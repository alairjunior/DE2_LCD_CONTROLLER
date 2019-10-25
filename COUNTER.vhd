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

entity COUNTER is
	generic
	(
		COUNT_BITS : integer := 32
	);

	port
	(
		-- Input ports
		CLK		: in	std_logic;
		EN			: in  std_logic;
		COUNT		: in	std_logic_vector(COUNT_BITS-1 downto 0);
		
		-- Output ports
		TC			: out std_logic
	);
end COUNTER;

architecture BEHAVIOR of COUNTER is					
	signal current: std_logic_vector(COUNT_BITS-1 downto 0);
begin
	process(CLK, EN)
	begin
		if (EN = '0') then
			current <= std_logic_vector(to_unsigned(0, COUNT_BITS));
		elsif (rising_edge(CLK)) then
			current <= std_logic_vector(unsigned(current) + to_unsigned(1, COUNT_BITS));
		end if;
	end process;
	
	TC <= '1' when current = COUNT else '0';
	
end BEHAVIOR;

