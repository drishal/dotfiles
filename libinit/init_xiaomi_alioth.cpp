/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_dalvik_heap.h>
#include <libinit_variant.h>

#include "vendor_init.h"

#define FINGERPRINT "google/raven/raven:12/SD1A.210817.036/7805805:user/release-keys"

static const variant_info_t aliothcn_info = {
    .hwc_value = "CN",
    .sku_value = "",

    .brand = "Redmi",
    .device = "alioth",
    .marketname = "K40",
    .model = "M2012K11AC",
    .build_fingerprint = FINGERPRINT,

    .nfc = true,
};

static const variant_info_t aliothin_info = {
    .hwc_value = "INDIA",
    .sku_value = "",

    .brand = "Xiaomi",
    .device = "aliothin",
    .marketname = "Mi 11X",
    .model = "M2012K11AI",
    .build_fingerprint = FINGERPRINT,

    .nfc = false,
};

static const variant_info_t alioth_info = {
    .hwc_value = "GLOBAL",
    .sku_value = "",

    .brand = "POCO",
    .device = "alioth",
    .marketname = "POCO F3",
    .model = "M2012K11AG",
    .build_fingerprint = FINGERPRINT,

    .nfc = true,
};

static const std::vector<variant_info_t> variants = {
    aliothcn_info,
    aliothin_info,
    alioth_info,
};

void vendor_load_properties() {
    search_variant(variants);
    set_dalvik_heap();
}
