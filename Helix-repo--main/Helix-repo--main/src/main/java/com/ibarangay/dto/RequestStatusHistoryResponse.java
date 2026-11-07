package com.ibarangay.dto;

import java.time.LocalDateTime;

public record RequestStatusHistoryResponse(

        Long historyId,

        Long requestId,

        Long adminId,

        String oldStatus,

        String newStatus,

        LocalDateTime changedAt,

        String remarks

) {
}