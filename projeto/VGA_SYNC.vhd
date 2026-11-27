-- Adaptado do VGA_SYNC fornecido: 640x480, PLL de 25 MHz, 800x525.
-- Coordenadas atuais para renderer com uma etapa de pipeline.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
entity VGA_SYNC is
    port(clock_50Mhz, red, green, blue : in std_logic;
         red_out, green_out, blue_out, horiz_sync_out, vert_sync_out,
         video_on, pixel_clock : out std_logic;
         pixel_row, pixel_column : out std_logic_vector(9 downto 0));
end VGA_SYNC;
architecture a of VGA_SYNC is
    signal pclk : std_logic;
    signal h : unsigned(9 downto 0) := (others=>'0');
    signal v : unsigned(9 downto 0) := (others=>'0');
    signal active, hs, vs : std_logic;
    signal active_d : std_logic := '0';
    signal hs_d, vs_d : std_logic := '1';
    component video_PLL is
        port(inclk0 : in std_logic; c0 : out std_logic);
    end component;
begin
    pll: video_PLL port map(inclk0=>clock_50Mhz,c0=>pclk);
    pixel_clock <= pclk;
    pixel_column <= std_logic_vector(h);
    pixel_row <= std_logic_vector(v);
    active <= '1' when h < 640 and v < 480 else '0';
    video_on <= active;
    hs <= '0' when h >= 656 and h < 752 else '1';
    vs <= '0' when v >= 490 and v < 492 else '1';
    process(pclk) begin
        if rising_edge(pclk) then
            if h=799 then
                h <= (others=>'0');
                if v=524 then v <= (others=>'0'); else v <= v+1; end if;
            else h <= h+1; end if;
            -- ROM de tiles tem um ciclo. RGB e sincronismos saem registrados.
            active_d <= active; hs_d <= hs; vs_d <= vs;
            red_out <= red and active_d;
            green_out <= green and active_d;
            blue_out <= blue and active_d;
            horiz_sync_out <= hs_d; vert_sync_out <= vs_d;
        end if;
    end process;
end a;
