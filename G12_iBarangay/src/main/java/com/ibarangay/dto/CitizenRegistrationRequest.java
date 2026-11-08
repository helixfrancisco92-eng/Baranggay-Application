package com.ibarangay.dto;

import java.time.LocalDate;

public record CitizenRegistrationRequest(

        String firstName,

        String middleName,

        String lastName,

        LocalDate dateOfBirth,

        String address,

        String contactNo,

        String email

) {
}