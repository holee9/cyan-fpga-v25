// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
// Date        : Mon Feb  2 16:26:46 2026
// Host        : work-dev running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/ip/indata_ram/indata_ram_sim_netlist.v
// Design      : indata_ram
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a35tfgg484-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "indata_ram,blk_mem_gen_v8_4_12,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_12,Vivado 2025.2" *) 
(* NotValidForBitStream *)
module indata_ram
   (clka,
    ena,
    wea,
    addra,
    dina,
    clkb,
    rstb,
    enb,
    addrb,
    doutb,
    rsta_busy,
    rstb_busy);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [7:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [23:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_mode = "slave BRAM_PORTB" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB RST" *) input rstb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [7:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [23:0]doutb;
  output rsta_busy;
  output rstb_busy;

  wire [7:0]addra;
  wire [7:0]addrb;
  wire clka;
  wire clkb;
  wire [23:0]dina;
  wire [23:0]doutb;
  wire ena;
  wire enb;
  wire rsta_busy;
  wire rstb;
  wire rstb_busy;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [23:0]NLW_U0_douta_UNCONNECTED;
  wire [7:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [7:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [23:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "8" *) 
  (* C_ADDRB_WIDTH = "8" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "1" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "1" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     3.5419 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "1" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "indata_ram.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "1" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "256" *) 
  (* C_READ_DEPTH_B = "256" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "24" *) 
  (* C_READ_WIDTH_B = "24" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "256" *) 
  (* C_WRITE_DEPTH_B = "256" *) 
  (* C_WRITE_MODE_A = "READ_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "24" *) 
  (* C_WRITE_WIDTH_B = "24" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  indata_ram_blk_mem_gen_v8_4_12 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(NLW_U0_douta_UNCONNECTED[23:0]),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[7:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(1'b0),
        .rsta_busy(rsta_busy),
        .rstb(rstb),
        .rstb_busy(rstb_busy),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[7:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[23:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
YqH9kwIC39+qbZg4PSfFsXuB9k9wnuxNryS/CfnEri6Ci9fSC6fsrQ/T/hnt3u/yolbJ8DJa1Qu6
Qnm24A9jLbA+fu3Nsmm6/rM6a4vU6OfVl/gTFd/CiWDutv6Dhn6Lim4uUNPahoOR/A2Yc4Zo2tdI
kMLO9gn9WlH2l3O2oXs=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XJYO2VHd/cnMxQd3i7/2qRhl57dl+doEKuhAunQyv3vpGRG/jlNxj8PqrgLoF0HMdqE3qJUVE/oq
kBSapqjVjLDMOrNGQ+Tc6VGsKMZH8FE/TXHQJ/IM5Iuiu2eozEwwVUomF+7cfqn+9OsVsqCONQ1M
g0oRlangiqasJDhhMfnlGGqwAwmgWRGQA6dmhTuua1s8zdvIv540zY6p5au8cAKVhqyyKK7wbxEE
SGuFqX+NYoyRV+rfWCcWM+hJEmnWS8LNAKkd13YE2+17sPYzUdZ23DmTxXK6KlAxKFW27CBySUfg
qdNXp2DSs2KAQYih27pBNMuHfGbM/ATFPWFvxg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
lYoEi/e8HsDTz6N11EDe/B/iitERmeYndlCklmCluwgb0N4W80JUGVlkd7NlRZHRNhxaNBJPkcjC
n61nO0tb17NwsMwjbY5TF8JWRYTNw1JXCFacvQYrdKv4/7QNQEtwVGiCLxFhOA8aHlWMZIrc2fri
VRMVWaEBcPwCGorlVIM=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QEw9fEsWFbdX0OQLvYs/gl+zyEOW3ak9TdQVaq+0AXXOT3LIqF7wDxJ6ZBnlf9mNbdsUVH5tAz1o
H8u7ihJl1L3THEvugW+TS8hkvVbEA9rKO2vV15KAj4Lla7UdFT/xDfe79RFarlLI7yGrubjgdoRi
QWy//UKsffG7IWNwmoSuppWiWB4ZHJtkunNyIkm70JPGyZF62VxJg1MTT+5LUbZG5vZjjuHZud9w
xJaKv1tFP/x8RVqLU5gPOqGqTW7/nKO2S+450Vo4D9vAmBVVcXpaL1EbSmCvQ+qJmcQKtf9qYFRV
Zko08hbpHjPxstqvTDro01jRzB8592m4xU2TWA==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
TC7q853CWBPPJgbRfgDV1lmjUwSAtliljShAyNFg8sfRfwDzchthzoSPH1UCHV++E2JXacEKq1lB
UWsNP92U4Xh0/Gu+6esOI0pJb8I+TRTxyBN1I4cRQEfQHcwfhbSdeH3yX9OV3opLEqYmT37hWU+J
zCawYnxVESI0FtRzEXve9gdEWlrKKckrT/hp4mvxxOjvOkOSQBvy0elgUOqh6mEOZl+JnUbsR+Wm
CoZLE1eefMZy3FnVmyDNPv3JPXi88aLXMyimal0MYFkTiS4XJiGT3eAIMIbksehXY+eYi/KFpZWQ
GHpX+lG3UmiWWLwyPakFwKEHbrBc70AlJ2eV9g==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
j9nmCKgjPWNChPbpSW6EWLrMA6oCG2JGPoum8px09v0PEAh0DRXZi0J8HPzXUsZgOEMcKpA7X54u
YFcDDCLAQ+urha/eSPbQYHQh4yGCursxAQ1C6LEyNQ2wJ0eLlO2bJeAl/gof06zqsYVM2lLJVNv5
wao1k2bmgPdfpfY3c9vPD0fSMuZPS41EoRS0cQhO5GTZnKdjxm6tEUL3GnTjB8ynSCIbCJUsMtAX
4FRHNa52gudx5B5fagR+lXgFhE7e++rWTJELr7SYB+r5Es8qZLTpCH8TrQxEkV0rY/+e4sAjNE2D
gHw8GD7VcUtc15B8y1BbVmh29qc8Nd3V2i/miA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
UkCD6I/Vye4qNoNoa3hIexBXG3xyKUJPAHAjIo7UcNVCDXpMQiYEtPDqExZMfiPlJn2nswCYIfIJ
FYWqMCloKSQyyI/7yZ2EtbyWEklb/P5IyZyvGi6hhFUo/JFTb12b4bK0gZPr+bCDdlVQKTx5GVHz
wptdUJO2omSj8axVMPbLRRtVzlJIZ29dTJ2ATXVXAcBxPnFfHRAMnYYKLeeLExX61vQvpqrkLQHm
XG7hpVzJi56gYKAzxa2BLq072OCVpVS70bfWlhlSTVcSlCrUf+EcarEk4FD8+Ih2NCvrqremG6yn
TtcBn8Xr8M/6zhOYvLi6AD6eArDMKA8n+Ccv8A==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
A5y5QVZU8yjPexRVPioSiAGohCHD5DX5FVobuMyhcgQRExLUhPvnnS8HOtxTj/2IapEcz68gFMGG
Hpi+m725u85/om/Vze9pGIW9Mn328Kz2FIg3W5EvGstfGwY+48LiAGAmTR269JS4lJGVYWYOz7Xk
S8cEsFd2m7j8iyKtARJzD90+UdXq/cIIh725jC9i8nbgxB364zddvm1Z/DF3JRw1qFp6GGcuRai1
KNcJ1j8c9wtIgktpsteU3e5+bxHEw8NT3gWXUFYjm00NDq97Jals8Jjktmum2nQxoF7ivPacfEey
gnSF6jRMkTsZObzc30hAhs0CEtc33hZLhPLHSn8pQ0WyvKJLHdd5s2yckgTZtqxC1Sbwe7WEgNXe
ZMX3pIkz+aoXsAL7GBLyVBMVQcyMoF0w8QGAaTe8sqatABwPqXidYRqNROTf62IYcMpV89XYgaTv
EwIn/oni9KOFd2BFVxRZbFGGC4IjvigsTBUijI+Dk6kVnDh240clGcc4

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Omtp+lCaqUx7Z4qdFj2zrN8LpCkit2eX4hlMtig+ielGm/x4FSZkpjoFmiqdKFPi2eg0pg09MSai
XyGH68UzAR7Xrj8f1jlIoUmMKp4GcxfdqfTeuu7kWGOJEP6cvgTjSJFj2gawDv7f4yZcltnK2x0L
e4GW/rBTmGvZtKWb2ahjINLxPuh3dDaSaWdb+zVgbtyrI5FrjxBkq+aOxSjyNsqnCx1L0uWbxnkl
88NbXN3dTaECXHNm/fsleayM5hKis7kTv9BFajJMGy+BhQlmIYpE+F5zchnTTFUFJZCz1sX9Fc8e
HcY7irB8mR3ajdzjUZLBQEMktp096Nheq3U75A==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
hpeBLwN9x2ZFDwroYLlUe5GjjDepHik2l0c2s3/6S7JPCRkzQSyt2V1Ad/JewAs/QNp5SXSbYYB4
rQl0My1LDMF3xw43r0g2IbcyHVpPhGp0W5msuQdF67afnsRv90iJYWLMI3QkYGCTWAzl4HrLxFSg
3z8XZRK670IcxznOrlvgHmIKsvubZrBkuc1EynrVb9Nw16QnIx2rc4WgcEXeFf+4i1RoYLDd3gXK
NFCNMdtaRYUThunFP6Z4ViZ5UnDmKq+IMhd31jTaqIlWOBDxPI1+v5RJYxIyTbn4rxlKR2fNbl5/
z4OUjBTd+1GH3I2OXlqmAOvIhpe2Z2HH7nZu/A==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Mt2RhTSUwEIEWeNARbyL+EdfS1UF6nPaL/fKl/7oO2gina93egwCWDLl1fbBtkfaPco0cu4MJ9K3
OraAsyHRlY+MNShmJ1LzAIA1LjZx4y55lu9dlQqSUXR7AW7wVbkg1864mK+hM/1XygU0jvebKNW9
B7xSER+asLO6pxi0mt7uC2PHxLPAYEszFhmnap82TtbDGdQ2qtyekY+ngs+N2fAdsblxVwJruiMl
e6XJ127M8N1mYwhWU2HtRpBOSnnKoHgD9fG51XK/rhk8DxT66QnX9uLPB+H25eDupBJGi1Y5o6x8
hOwZiSUVlBLh7brfzevh7+eRn+7es6wBas0+3w==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 28672)
`pragma protect data_block
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
rA==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
