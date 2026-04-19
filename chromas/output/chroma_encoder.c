/*
==============================================================
PRISM Downloadable Configuration

Input:    chroma_encoder.sv
Config:   tinyqv16.cfg
==============================================================
*/

#include <stdint.h>

const uint32_t chroma_encoder[] =
{
   0x00001780, 0x0001e000, 
   0x00001780, 0x0001c000, 
   0x00001780, 0x0001a000, 
   0x00001780, 0x00018000, 
   0x00001780, 0x00016000, 
   0x00001780, 0x00014000, 
   0x00001780, 0x00012000, 
   0x00001780, 0x00010000, 
   0x00001780, 0x0000e000, 
   0x00001780, 0x0000c000, 
   0x00001780, 0x0000a000, 
   0x000017a0, 0x00000000, 
   0x00001482, 0x00000021, 
   0x00001308, 0x41000180, 
   0x00001508, 0x01006015, 
   0x00001310, 0x40002180, 

};
const uint32_t chroma_encoder_count   = 16;
const uint32_t chroma_encoder_width   = 45;
const uint32_t chroma_encoder_ctrlReg = 0x00003000;
