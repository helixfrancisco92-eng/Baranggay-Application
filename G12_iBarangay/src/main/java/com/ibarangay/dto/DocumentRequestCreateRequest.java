package com.ibarangay.dto;

public record DocumentRequestCreateRequest(

        Long citizenId,

        Long documentTypeId,

        String purpose

) {
}