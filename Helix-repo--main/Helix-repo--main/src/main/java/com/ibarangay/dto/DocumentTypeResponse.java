package com.ibarangay.dto;

import java.math.BigDecimal;

public record DocumentTypeResponse(
        Long documentTypeId,
        String name,
        String description,
        int processingDays,
        BigDecimal fee,
        boolean active
) {
}