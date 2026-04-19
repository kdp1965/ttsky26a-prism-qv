/*
==============================================================
PRISM Downloadable Configuration

Input:    chroma_spislave.sv
Config:   tinyqv16.cfg
==============================================================
*/

#include <stdint.h>

const uint32_t chroma_spislave[] =
{
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x00001780, 0x00001a00, 
   0x000017f1, 0x00003a00, 
   0x00001280, 0x00005a1d, 
   0x00001700, 0x00001a00, 
   0x00001284, 0x0000da03, 
   0x00001700, 0x00001a00, 
   0x00001500, 0x40009a03, 
   0x00001401, 0x00005bc3, 
   0x00001080, 0x00003a00, 

};
const uint32_t chroma_spislave_count   = 16;
const uint32_t chroma_spislave_width   = 45;
const uint32_t chroma_spislave_ctrlReg = 0x00002952;
