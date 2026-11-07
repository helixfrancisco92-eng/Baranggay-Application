package com.ibarangay.dto;

public record DocumentRequirementResponse(

        Long requirementId,

        String name,

        String description,

        boolean required

) {
}