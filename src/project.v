/*
 * Copyright (c) 2024 Daniel
 * SPDX-License-Identifier: Apache-2.0
 */
 
`default_nettype none
 
/*
 * Tiny Tapeout Wrapper para SPI Slave
 * 
 * Este módulo adapta la interfaz del SPI slave a los pines estándar de Tiny Tapeout.
 * 
 * Pinout:
 *   ui_in[0]   = sck         (SPI Clock del maestro)
 *   ui_in[1]   = cs_n        (Chip Select activo bajo)
 *   ui_in[2]   = mosi        (Master Out Slave In)
 *   ui_in[7:3] = tx_data[4:0] (Datos a transmitir, bits 0-4)
 *   
 *   uio_in[2:0]  = tx_data[7:5] (Datos a transmitir, bits 5-7) - entrada
 *   uio_out[4:3] = rx_data[7:6] (Datos recibidos, bits 6-7) - salida
 *   
 *   uo_out[0]   = miso        (Master In Slave Out)
 *   uo_out[1]   = rx_valid    (Pulso: byte recibido)
 *   uo_out[7:2] = rx_data[5:0] (Datos recibidos, bits 0-5)
 */
 
module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
 
  // =====================================================================
  // Señales internas del SPI slave
  // =====================================================================
  wire       sck;
  wire       cs_n;
  wire       mosi;
  wire       miso;
  wire [7:0] tx_data;
  wire [7:0] rx_data;
  wire       rx_valid;
  
  // =====================================================================
  // Mapeo de ENTRADAS (ui_in)
  // =====================================================================
  assign sck           = ui_in[0];
  assign cs_n          = ui_in[1];
  assign mosi          = ui_in[2];
  assign tx_data[4:0]  = ui_in[7:3];
  
  // =====================================================================
  // Mapeo de BIDIRECCIONALES (uio_in) - como entradas para tx_data alto
  // =====================================================================
  assign tx_data[7:5] = uio_in[2:0];
  
  // =====================================================================
  // Instancia del SPI Slave
  // =====================================================================
  spi_slave #(
      .CPOL(0),   // Clock inactivo en bajo
      .CPHA(0)    // Muestra en primer flanco (subida), desplaza en bajada
  ) spi_inst (
      .clk(clk),
      .rst_n(rst_n),
      .sck(sck),
      .cs_n(cs_n),
      .mosi(mosi),
      .miso(miso),
      .tx_data(tx_data),
      .rx_data(rx_data),
      .rx_valid(rx_valid)
  );
  
  // =====================================================================
  // Mapeo de SALIDAS (uo_out)
  // =====================================================================
  assign uo_out[0]     = miso;
  assign uo_out[1]     = rx_valid;
  assign uo_out[7:2]   = rx_data[5:0];
  
  // =====================================================================
  // Mapeo de BIDIRECCIONALES (uio_out) - como salidas para rx_data alto
  // =====================================================================
  // Bits 0-2: entradas (tx_data[7:5]) - sin driver
  // Bits 3-4: salidas (rx_data[7:6])
  // Bits 5-7: no usados - sin driver
  
  assign uio_out[2:0]  = 3'h0;           // No driven (entrada)
  assign uio_out[4:3]  = rx_data[7:6];   // Salida
  assign uio_out[7:5]  = 3'h0;           // No used
  
  // =====================================================================
  // Control de output enables para pines bidireccionales
  // uio_oe[i] = 1 → pin es output
  // uio_oe[i] = 0 → pin es input (alta impedancia)
  // =====================================================================
  
  assign uio_oe[2:0] = 3'b000;   // Bits 0-2: entrada (oe = 0, entrada)
  assign uio_oe[4:3] = 2'b11;    // Bits 3-4: salida (oe = 1, output)
  assign uio_oe[7:5] = 3'b000;   // Bits 5-7: no usado (oe = 0)
  
  // =====================================================================
  // Prevención de advertencias por pines no utilizados
  // =====================================================================
  wire _unused = &{ena, 1'b0};
 
endmodule
