-----------------------------------------------------------------------------------------
--
--  Copyright 2016 Alair Dias Junior
--
--  This file is part of LCD_CONTROLLER.
--
--  LCD_CONTROLLER is free software: you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software Foundation,
--  either version 3 of the License, or any later version.
--
--  LCD_CONTROLLER is distributed in the hope that it will be useful, but WITHOUT ANY  
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License along with 
--  LCD_CONTROLLER. If not, see http://www.gnu.org/licenses/.
-- 
--
-----------------------------------------------------------------------------------------


library ieee;
-- STD_LOGIC and STD_LOGIC_VECTOR types, and relevant functions
use ieee.std_logic_1164.all;

-- SIGNED and UNSIGNED types, and relevant functions
use ieee.numeric_std.all;

entity LCD_CONTROLLER is
	port
	(
		-- Input ports
		RESET		: in  std_logic;
		CLEAR		: in	std_logic;
		W			: in	std_logic;
		CLK		: in	std_logic;
		CLK_100n	: in	std_logic;							-- CLK MUST be 0.1us
		POSITION : in  std_logic_vector(4 downto 0);
		CHA		: in	std_logic_vector(7 downto 0);
		
		-- Output ports
		DATA		: out std_logic_vector(7 downto 0);
		RW			: out std_logic;
		BLON		: out std_logic;
		EN			: out std_logic;
		ON_PIN	: out std_logic;
		RS			: out std_logic
	);
end LCD_CONTROLLER;

architecture BEHAVIOR of LCD_CONTROLLER is
	type state is (RESET_STATE, RESET_WAIT,
						POWER_ON, FUNCTION_SET, DISPLAY_ON_OFF_CONTROL, DISPLAY_CLEAR, ENTRY_MODE_SET, 					
						READY, CLEAR_STATE,
						WRITE_ADDRESS, WRITE_DATA);

	-- data memory
	type DATA_MEMORY is array (31 downto 0) of std_logic_vector(7 downto 0);
	signal in_memory: DATA_MEMORY;
	
	-- waitCounter
	signal waitCount : std_logic_vector(18 downto 0);
	signal enableCount: std_logic;
	signal endWait: std_logic;
	
	-- dataSender
	signal sendingData: std_logic;
	signal sendData: std_logic;
	
	-- stateMachine
	signal currentState : state := RESET_STATE;
	signal nextState : state;
	signal currentPosition, nextPosition: std_logic_vector(4 downto 0);
	signal incPosition: std_logic;
		
	
begin

	waitCounter : work.COUNTER
			generic map( COUNT_BITS => 19 )
			port map (CLK => CLK_100n, EN => enableCount, COUNT => waitCount, TC => endWait);
	
	dataSender : work.LCD_DATA_SENDER port map (CLK => CLK_100n, EN => sendData, LCD_EN => EN, BUSY => sendingData);

	BLON <= '0';					
	

	
	process(CLEAR, CLK, W)
	begin
		if (CLEAR = '1') then
			for I in 0 to 31 loop
				in_memory(I) <= x"20"; -- write spaces
			end loop;
		elsif (rising_edge(CLK) and W = '1') then
			in_memory(to_integer(unsigned(POSITION))) <= CHA;
		end if;
	end process;
	

	process (CLK_100n, RESET)
	begin
		if (RESET = '1') then
			currentState <= RESET_STATE;
			currentPosition <= "00000";
		elsif (rising_edge(CLK_100n)) then
			currentState <= nextState;
			if (incPosition = '1') then
				currentPosition <= nextPosition;
			end if;
		end if;
	end process;
	

	
	process(CLK_100n)
	begin
		if (falling_edge(CLK_100n)) then	
	
			case currentState is -- MEALY MACHINE
				
				when RESET_STATE =>
					nextState 	<= RESET_WAIT;
					DATA 			<= "XXXXXXXX";
					RW 			<= 'X';
					ON_PIN 		<= '0';
					RS 			<= 'X';
					waitCount	<= (others => 'X');
					enableCount <= '0';
					sendData		<= '0';
					incPosition	<= '0';
					
				when RESET_WAIT => 
					if (endWait = '0') then 
						nextState 	<= RESET_WAIT;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '0';
						RS 			<= 'X';
						waitCount 	<= std_logic_vector(to_unsigned(300000, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= POWER_ON;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount	<= (others => 'X');
						enableCount <= '0';
						sendData		<= '0';
						incPosition	<= '0';
					end if;	
			
				when POWER_ON =>
					if (endWait = '0') then 
						nextState <= POWER_ON;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(300000, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= FUNCTION_SET;
						DATA 			<= "001111XX";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount	<= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;
					
							
				when FUNCTION_SET =>
					if (sendingData = '1') then 
						nextState <= FUNCTION_SET;
						DATA 			<= "001111XX";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= FUNCTION_SET;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(390, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= DISPLAY_ON_OFF_CONTROL;
						DATA 			<= "00001100";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;
				
				when DISPLAY_ON_OFF_CONTROL =>
					if (sendingData = '1') then 
						nextState <= DISPLAY_ON_OFF_CONTROL;
						DATA 			<= "00001100";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= DISPLAY_ON_OFF_CONTROL;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(390, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= DISPLAY_CLEAR;
						DATA 			<= "00000001";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;

				when DISPLAY_CLEAR =>
					if (sendingData = '1') then 
						nextState <= DISPLAY_CLEAR;
						DATA 			<= "00000001";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= DISPLAY_CLEAR;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(15300, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= ENTRY_MODE_SET;
						DATA 			<= "00000110";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;
				
				when ENTRY_MODE_SET =>
					if (sendingData = '1') then 
						nextState <= ENTRY_MODE_SET;
						DATA 			<= "00000110";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= ENTRY_MODE_SET;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(15300, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= READY;
						DATA 			<= "00000110";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '0';
						incPosition	<= '0';
					end if;

				
				when READY =>
					if (CLEAR = '1') then
						nextState <= CLEAR_STATE;
						DATA 			<= "00000001";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					else
						nextState <= WRITE_ADDRESS;
						DATA 			<= "1" & currentPosition(4) & "00" & currentPosition(3 downto 0);
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;
					
				when CLEAR_STATE =>
					if (sendingData = '1') then 
						nextState <= CLEAR_STATE;
						DATA 			<= "00000001";
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= CLEAR_STATE;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(15300, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= READY;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '0';
						incPosition	<= '0';
					end if;
					
				
				when WRITE_ADDRESS=>
					if (sendingData = '1') then 
						nextState <= WRITE_ADDRESS;
						DATA 			<= "1" & currentPosition(4) & "00" & currentPosition(3 downto 0);
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '0';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= WRITE_ADDRESS;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(390, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= WRITE_DATA;
						DATA 			<= in_memory(to_integer(unsigned(currentPosition)));
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '1';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					end if;
				
				when WRITE_DATA =>
					if (sendingData = '1') then 
						nextState <= WRITE_DATA;
						DATA 			<= in_memory(to_integer(unsigned(currentPosition)));
						RW 			<= '0';
						ON_PIN 		<= '1';
						RS 			<= '1';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '1';
						incPosition	<= '0';
					elsif (endWait = '0') then
						nextState <= WRITE_DATA;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= std_logic_vector(to_unsigned(430, 19));
						enableCount <= '1';
						sendData		<= '0';
						incPosition	<= '0';
					else
						nextState <= READY;
						DATA 			<= "XXXXXXXX";
						RW 			<= 'X';
						ON_PIN 		<= '1';
						RS 			<= 'X';
						waitCount <= (others => 'X');
						enableCount <= '0';
						sendData		<= '0';
						incPosition	<= '1';
					end if;
			end case;
		end if;
	end process;
	
	nextPosition <= std_logic_vector(unsigned(currentPosition) + to_unsigned(1,5));
	
	
	
end BEHAVIOR;

