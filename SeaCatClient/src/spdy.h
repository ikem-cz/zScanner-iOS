#ifndef _SEACATCC_SPDY_H_
#define _SEACATCC_SPDY_H_

/*
SPDY Protocol - Draft 3.1

http://www.chromium.org/spdy/spdy-protocol/spdy-protocol-draft3-1

*/

// Forward declaration
struct iobuf_block;
struct host_base;
struct host_http;

// SPDY constants

#define SEACATCC_SPDY_HEADER_SIZE (8)

#define SEACATCC_SPDY_FLAG_FIN 0x01
#define SEACATCC_SPDY_FLAG_UNIDIRECTIONAL 0x02
#define SEACATCC_ALX1_FLAG_CSR_NOT_FOUND 0x80

#define SEACATCC_SPDY_CNTL_FRAME_VERSION_SPD3 0x03
#define SEACATCC_SPDY_CNTL_FRAME_VERSION_ALX1 0xA1

#define SEACATCC_SPDY_CNTL_TYPE_SYN_STREAM 1
#define SEACATCC_SPDY_CNTL_TYPE_SYN_REPLY 2
#define SEACATCC_SPDY_CNTL_TYPE_RST_STREAM 3
#define SEACATCC_SPDY_CNTL_TYPE_PING 6

#define SEACATCC_SPDY_CNTL_TYPE_STATS_REQ 0xA1
#define SEACATCC_SPDY_CNTL_TYPE_STATS_REP 0xA2

#define SEACATCC_SPDY_CNTL_TYPE_CSR 0xC1
#define SEACATCC_SPDY_CNTL_TYPE_CERT_QUERY 0xC2
#define SEACATCC_SPDY_CNTL_TYPE_CERT 0xC3

#define SEACATCC_SPDY_RST_STATUS_PROTOCOL_ERROR 1
#define SEACATCC_SPDY_RST_STATUS_INVALID_STREAM 2
#define SEACATCC_SPDY_RST_STATUS_REFUSED_STREAM 3
#define SEACATCC_SPDY_RST_STATUS_INTERNAL_ERROR 6
#define SEACATCC_SPDY_RST_STATUS_STREAM_ALREADY_CLOSED 9

////

void seacatcc_alx1_csr_build(void * frame, uint16_t frame_len);
uint16_t seacatcc_alx1_cert_query_build(void * frame, uint16_t frame_len, uint16_t query_type);

void seacatcc_spdy_cntl_frame_hdr_parse(uint8_t * data, uint16_t * version, uint16_t * type, uint8_t * flags, uint32_t * length);
void seacatcc_spdy_data_frame_hdr_parse(uint8_t * data, uint32_t * stream_id, uint8_t * flags, uint32_t * length);

#endif //_SEACATCC_SPDY_H_
