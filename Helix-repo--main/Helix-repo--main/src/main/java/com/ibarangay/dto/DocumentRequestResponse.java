package com.ibarangay.dto;

import java.time.LocalDateTime;

public record DocumentRequestResponse(

        Long requestId,

        Long citizenId,

        String citizenName,

        Long documentTypeId,

        String documentName,

        LocalDateTime requestDate,

        String purpose,

        String status,

        String remarks,

        LocalDateTime processedAt,

        LocalDateTime releasedAt

) {
}