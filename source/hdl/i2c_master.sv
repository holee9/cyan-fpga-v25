`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// Module: i2c_master
// Description: I2C master controller for ROIC sensor configuration
//              Implements I2C write protocol to configure ROIC registers
//              via GPIO gate signals. Generates SCL clock at ~1.25MHz from
//              25MHz input clock (20:1 divider).
//
// Author: CYAN-FPGA Team
// Company: DRK Technologies
// Creation Date: 2024-06-05
// Version: 1.0
//
// Parameters:
//   - SLAVE_ADDR: Default I2C slave address (8'hE8 = 0x74 7-bit + R/W bit)
//   - DELAY_2MS: Delay counter value for 2ms delay between writes
//
// Revision History:
//   1.0 (2024-06-05) - Initial creation
//-----------------------------------------------------------------------------

module i2c_master(
    output wire scl_out, 
    inout wire sda,
    input wire s_clk_25mhz,
    input wire [15:0] gate_gpio_data 
);

    wire start = 1;
    reg busy = 0;
    reg [31:0] led_clk = 0;
    reg [3:0] write_counter;
//    reg [7:0] state = IDLE;                 
    reg [7:0] state;                 
    reg [7:0] bit_cnt;
    reg [7:0] scl_count = 0;               
    reg [7:0] scl_count_1 = 0;              
    
    reg sda_dir;  
    reg sda_out =1;                        
    reg scl;            
    reg scl_1;       
    reg scl_h =1;       
    
    
    reg scl_sel;     
    reg [1:0] phase;   
    wire sda_in = 0;  
    
    reg sda_1;          
    
    reg [23:0] delay_counter; 
    reg [7:0] data_to_slave;  
    reg [7:0] data_to_slave2;  
    reg [7:0] slave_address;  
    
    // I2C timing parameters (clock counts at 25MHz input)
    parameter SCL_HIGH_COUNT = 10,   // SCL high time count (400ns @ 25MHz)
    parameter SCL_LOW_COUNT = 20,    // SCL low time count (800ns @ 25MHz)
    parameter BIT_COUNT_MAX = 7,     // Bit index for 8-bit data (0-7)

    parameter SLAVE_ADDR = 8'hE8;
    parameter IDLE = 0, START = 1, WRITE_ADDR = 2, WRITE_DATA = 3,WRITE_DATA2 = 8,
              READ_DATA = 4, STOP = 5, ACK = 6, DELAY = 7;
    parameter DELAY_2MS = 100;     

    
    assign sda = sda_dir ? sda_out : 1'bz;     
    assign scl_out = scl_sel ? scl : scl_h;       



    always @(posedge s_clk_25mhz) begin
        scl_count = scl_count +1; 
       if(scl_count == SCL_HIGH_COUNT) begin 
            scl = 1;                   
       end else if(scl_count == SCL_LOW_COUNT) begin
            scl = 0;
            scl_count = 0;
       end     
    end              


    always @(posedge scl)begin
        if(state == WRITE_ADDR)begin
            scl_h =0;       
        end else begin
            scl_h =1;
        end 
    end      
   
        
    always @(negedge scl) begin         
        case (state)
                IDLE: begin             
                    if (!busy) begin    
                        busy <= 1;
                        state <= START;
                        write_counter <= 0;          
                        slave_address <= SLAVE_ADDR;
                        data_to_slave <= 8'h06;     
                        data_to_slave2 <= 8'h00;    
                        bit_cnt <= 0;              
                    end
                end
                
                START: begin
                    sda_dir <= 1;                   
                    state <= WRITE_ADDR;
                    sda_out <= 0;               
                end
                
                WRITE_ADDR: begin
                    scl_sel =1;                 
                    sda_out <= slave_address[7 - bit_cnt];   
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == BIT_COUNT_MAX) begin           
                            state <= ACK;
                            bit_cnt <= 0;
                       phase <= 0;
                        end
                end
             
                ACK: begin                  
                    sda_dir <= 0;             
                    if (sda_in == 0)begin 
                        if(phase == 0)begin
                            state <= WRITE_DATA;    
                        end else if(phase == 1) begin   
                            state <= WRITE_DATA2;
                        end else if(phase == 2) begin
                            state <= ACK;
                            phase <= 3;      
                        end else if(phase == 3) begin
                            state <= DELAY;         
                            delay_counter <= DELAY_2MS;                  
                            busy <= 0;            
                            sda_out <= 0;                  
                        end
                            sda_dir <= 1;
                            bit_cnt <= 0;
                    end else begin
                        state <= IDLE;   
                        busy <= 0;
                    end  
                end     
             
                WRITE_DATA: begin
                    phase <= 1;
                        sda_out <= data_to_slave[7 - bit_cnt];
                        bit_cnt <= bit_cnt + 1;
                    if(bit_cnt == BIT_COUNT_MAX)begin
                            state <= ACK;
                            bit_cnt <= 0;
                    end
                end        
    
                WRITE_DATA2: begin
                    phase <= 2;
                    sda_out <= data_to_slave2[7 - bit_cnt];
                    bit_cnt <= bit_cnt + 1;
                    if(bit_cnt == BIT_COUNT_MAX)begin
                       state <= ACK;
                       bit_cnt <= 0;
                       write_counter <= write_counter + 1;
                    end
                end     
                
                DELAY: begin
                    scl_sel =0;         
                    sda_out =1;           
                    if (delay_counter > 0) begin
                        delay_counter <= delay_counter - 1;
                    end else if (write_counter == 1) begin
                        slave_address <= SLAVE_ADDR;     
                        data_to_slave <= 8'h02;     
                        data_to_slave2 <= gate_gpio_data[7:0];         
                        state <= START;
                     end else if (write_counter == 2) begin
                        slave_address <= SLAVE_ADDR;     
                        data_to_slave <= 8'h07;     
                        data_to_slave2 <= 8'h00;                          
                        state <= START;
                     end else if (write_counter == 3) begin
                        slave_address <= SLAVE_ADDR;     
                        data_to_slave <= 8'h03;    
                        data_to_slave2 <= gate_gpio_data[15:8]; 
                        state <= START;
                    end else begin
                            state <= STOP;      
                    end
                end
             
                STOP: begin
                    sda_dir <= 1;
                    sda_out = 1;                       
                    scl_sel =0;            
                    state <= IDLE;        
                    busy <= 0;
                end
                
                default : state <= IDLE;
                
        endcase         
    end                     

endmodule



//240605.1334