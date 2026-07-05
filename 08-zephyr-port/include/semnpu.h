/* Application API for the SemNPU coprocessor. */
#ifndef SEMNPU_H_
#define SEMNPU_H_

#include <stddef.h>
#include <stdint.h>
#include <zephyr/device.h>

/* a and b are 128-bit vectors as 4 little-endian words each */
uint32_t semnpu_popand(const struct device *dev,
		       const uint32_t a[4], const uint32_t b[4]);
uint32_t semnpu_hamming(const struct device *dev,
			const uint32_t a[4], const uint32_t b[4]);

/* dot product of n signed int8 pairs */
int32_t semnpu_dot8(const struct device *dev,
		    const int8_t *a, const int8_t *b, size_t n);

#endif /* SEMNPU_H_ */
