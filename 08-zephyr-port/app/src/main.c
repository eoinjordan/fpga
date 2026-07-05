/* SemNPU sample: same test data as stage 06's firmware, so the numbers
 * printed here must be popand=51 hamming=36 dot8=-5063 -- the fourth
 * layer of the stack (Python golden, RTL, bare-metal RV32I, Zephyr)
 * agreeing on the same answers.
 */
#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <stdio.h>
#include "semnpu.h"

/* VEC_A = 0xDEADBEEF_C0FFEE00_12345678_0F0F0F0F, little-endian words */
static const uint32_t vec_a[4] = {0x0F0F0F0F, 0x12345678, 0xC0FFEE00, 0xDEADBEEF};
static const uint32_t vec_b[4] = {0x00FF00FF, 0x87654321, 0xC0FFEE00, 0xFEEDFACE};

static const int8_t dot_a[6] = {100, -128, 7, -1, 127, 0};
static const int8_t dot_b[6] = {-50, 127, 9, -1, 127, 55};

int main(void)
{
	const struct device *npu = DEVICE_DT_GET(DT_NODELABEL(semnpu0));

	if (!device_is_ready(npu)) {
		printf("semnpu0 not ready\n");
		return 1;
	}

	printf("popand  = %u\n", semnpu_popand(npu, vec_a, vec_b));
	printf("hamming = %u\n", semnpu_hamming(npu, vec_a, vec_b));
	printf("dot8    = %d\n", semnpu_dot8(npu, dot_a, dot_b, 6));

	return 0;
}
