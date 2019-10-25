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

entity LCD_DATA_SENDER is

	port
	(
		-- Input ports
		CLK		: in	std_logic;
		EN			: in  std_logic;
		
		-- Output ports
		LCD_EN	: out std_logic;
		BUSY		: out std_logic
	);
end LCD_DATA_SENDER;

architecture BEHAVIOR of LCD_DATA_SENDER is					
	type STATE is (IDLE, PREPARE, SEND, HOLD, COMPLETED);
	signal currentCount, nextCount: std_logic_vector(6 downto 0);
	signal currentState, nextState: STATE;
begin
	process(CLK, EN)
	begin
		if (EN = '0') then 
			currentCount <= std_logic_vector(to_unsigned(0, 7));
			currentState <= IDLE;
		elsif (rising_edge(CLK)) then
			currentState <= nextState;
			currentCount <= nextCount;
		end if;
	end process;
	
	process(currentState, currentCount)
	begin
		case currentState is
			when IDLE =>
				LCD_EN <= '0';
				BUSY <= '0';
				nextState <= PREPARE;
				nextCount <= std_logic_vector(to_unsigned(100, 7));
				
			when PREPARE =>
				if (currentCount /= std_logic_vector(to_unsigned(0, 7))) then
					LCD_EN <= '1';
					BUSY <= '1';
					nextState <= PREPARE;
					nextCount <= std_logic_vector(unsigned(currentCount) - to_unsigned(1, 7));
				else
					LCD_EN <= '0';
					BUSY <= '1';
					nextState <= SEND;
					nextCount <= (others=>'X');
				end if;
				
			when SEND =>
				LCD_EN <= '0';
				BUSY <= '1';
				nextState <= HOLD;
				nextCount <= std_logic_vector(to_unsigned(100, 7));
				
			when HOLD =>
				if (currentCount /= std_logic_vector(to_unsigned(0, 7))) then
					LCD_EN <= '0';
					BUSY <= '1';
					nextState <= HOLD;
					nextCount <= std_logic_vector(unsigned(currentCount) - to_unsigned(1, 7));
				else
					LCD_EN <= '0';
					BUSY <= '0';
					nextState <= COMPLETED;
					nextCount <= (others=>'X');
				end if;
			
			when COMPLETED =>
				LCD_EN <= '0';
				BUSY <= '0';
				nextState <= COMPLETED;
				nextCount <= (others=>'X');
			
		end case;
	end process;
	
end BEHAVIOR;

