/*
 * SemNPU driver. The register offsets mirror semnpu_regs.v exactly --
 * if you change the RTL map, change it here and in the binding docs.
 *
 * The base address is NOT hardcoded: DT_INST_REG_ADDR pulls it from the
 * devicetree node compatible with "eoin,semnpu" at compile time.
 */
#define DT_DRV_COMPAT eoin_semnpu

#include <zephyr/device.h>
#include <zephyr/sys/sys_io.h>
#include <zephyr/toolchain.h>    /* ARG_UNUSED */
#include "semnpu.h"

#define REG_A(i)     (0x00 + 4 * (i))
#define REG_B(i)     (0x10 + 4 * (i))
#define REG_POPAND    0x20
#define REG_HAMMING   0x24
#define REG_STREAM    0x28
#define REG_CLEAR     0x2C
#define REG_ACC       0x30

struct semnpu_config {
	mem_addr_t base;
};

static inline mem_addr_t base_of(const struct device *dev)
{
	return ((const struct semnpu_config *)dev->config)->base;
}

static void load_vectors(const struct device *dev,
			 const uint32_t a[4], const uint32_t b[4])
{
	mem_addr_t base = base_of(dev);

	for (int i = 0; i < 4; i++) {
		sys_write32(a[i], base + REG_A(i));
		sys_write32(b[i], base + REG_B(i));
	}
}

uint32_t semnpu_popand(const struct device *dev,
		       const uint32_t a[4], const uint32_t b[4])
{
	load_vectors(dev, a, b);
	return sys_read32(base_of(dev) + REG_POPAND);
}

uint32_t semnpu_hamming(const struct device *dev,
			const uint32_t a[4], const uint32_t b[4])
{
	load_vectors(dev, a, b);
	return sys_read32(base_of(dev) + REG_HAMMING);
}

int32_t semnpu_dot8(const struct device *dev,
		    const int8_t *a, const int8_t *b, size_t n)
{
	mem_addr_t base = base_of(dev);

	sys_write32(1, base + REG_CLEAR);
	for (size_t i = 0; i < n; i++) {
		sys_write32((uint32_t)(uint8_t)a[i] |
			    ((uint32_t)(uint8_t)b[i] << 8),
			    base + REG_STREAM);
	}
	return (int32_t)sys_read32(base + REG_ACC);
}

static int semnpu_init(const struct device *dev)
{
	ARG_UNUSED(dev);
	return 0;
}

#define SEMNPU_DEFINE(inst)                                                  \
	static const struct semnpu_config semnpu_config_##inst = {          \
		.base = DT_INST_REG_ADDR(inst),                              \
	};                                                                   \
	DEVICE_DT_INST_DEFINE(inst, semnpu_init, NULL, NULL,                 \
			      &semnpu_config_##inst, POST_KERNEL,            \
			      CONFIG_KERNEL_INIT_PRIORITY_DEVICE, NULL);

DT_INST_FOREACH_STATUS_OKAY(SEMNPU_DEFINE)
