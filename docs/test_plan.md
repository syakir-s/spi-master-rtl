# spi\_master Test Plan



## Principle



All the tests listed are paired with an expected outcome based on the component datasheet and design spec, not on the RTL, to make the testbench independent from the design. This allows me to find bugs.



## Checks



|ID|Category|Check|Expected|Source|
|-|-|-|-|-|
|T1|Functional|reads 0x00|slave receives 0x0B > 0x00; data\_out = 0xAD|Rev. G p. 21 (read command 0x0B); p. 25 (DEVID\_AD = 0xAD)|
|T2|Functional|write 0xAB to 0x2C|slave receives 0x0A > 0x2C > 0xAB; reg 0x2C = 0xAB; data\_out = 0xAD (remain)|Rev. G p. 21 (write command 0x0A); p. 25 (0x2C is RW); design spec (data\_out holds through writes)|
|P1|Protocol|SCLK idle|SCLK low whenever cs is high (read/write)|Rev. G p. 21 (CPOL = 0, SCLK idles low)|
|P2|Protocol|edges|MOSI bit shifted on SCLK falling edge; sampled on rising edge (read/write)|Rev. G p. 21 (CPHA = 0); Figures 41–42|
|P3|Protocol|bit order|MSB-first (read/write)|Rev. G, Figures 41–42 (MSB first, LSB last)|
|P4|Protocol|pulse count|exactly 24 SCLK pulses per transaction (read/write)|Rev. G p. 21 (framing: 3 bytes × 8 bits)|
|C1|CS Timing|tCSS|CS falling > first SCLK rising ≥ 100 ns|Rev. G Table 10 (tCSS ≥ 100 ns)|
|C2|CS Timing|tCSH|last SCLK falling > CS rising ≥ 20 ns|Rev. G Table 10 (tCSH ≥ 20 ns)|
|C3|CS Timing|tCSD|two back-to-back transactions: CS rising > next CS falling ≥ 20 ns|Rev. G Table 10 (tCSD ≥ 20 ns)|
|I1|Interface Contract|busy|rises with cs falling; high while cs is low; falls 30 ns after cs rises|design spec (busy definition, DISABLE = 3 cycles)|
|I2|Interface Contract|ignored pulse|start\_spi during busy gives exactly 1 CS falling edge|design spec (start\_spi pulse contract)|
|I3|Interface Contract|input capture|change address\_in mid-read of 0x00; slave gets 0x00; data\_out = 0xAD|design spec (input capture at start\_spi)|
|R1|Reset|reset|cs = 1, sclk = 0, mosi = 1, busy = 0, data\_out = 0xFF|design spec (reset values)|
|E1|Edge Cases|write > read|write 0xAB to 0x2C, read 0x2C gives 0xAB|Rev. G p. 25 (0x2C is RW)|
|E2|Edge Cases|reset mid-transaction|same as R1|design spec (reset from any state)|
|E3|Edge Cases|two reads|0x00 gives 0xAD, then 0x02 gives 0xF2|Rev. G p. 25 (DEVID\_AD = 0xAD, PARTID = 0xF2)|



