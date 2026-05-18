#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/completion.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/slab.h>
#include "snn_ioctl.h"

#define DEVICE_NAME "snn_accel"
#define DMA_BUF_SIZE (4 * 1024 * 1024)  /* 4 MB -- fits 1M AER events */

/* DMA register offsets */
#define DMA_MM2S_CR     0x00
#define DMA_MM2S_SR     0x04
#define DMA_MM2S_SA     0x18
#define DMA_MM2S_LENGTH 0x28
#define DMA_S2MM_CR     0x30
#define DMA_S2MM_SR     0x34
#define DMA_S2MM_DA     0x48
#define DMA_S2MM_LENGTH 0x58
#define DMA_CR_RUN        BIT(0)
#define DMA_CR_RESET      BIT(2)
#define DMA_CR_IOC_IRQ_EN BIT(12)
#define DMA_SR_IOC_IRQ    BIT(12)

/* CSR register offsets */
#define CSR_CFG_MASK    0x00
#define CSR_CFG_DELAY   0x04
#define CSR_STATUS      0x08

struct snn_priv {
    void __iomem    *dma_base;
    void __iomem    *csr_base;

    void            *tx_virt;
    dma_addr_t       tx_phys;
    void            *rx_virt;
    dma_addr_t       rx_phys;

    struct completion tx_done;
    struct completion rx_done;

    struct cdev      cdev;
    dev_t            devno;
    struct class    *cls;
    struct device   *dev;
};