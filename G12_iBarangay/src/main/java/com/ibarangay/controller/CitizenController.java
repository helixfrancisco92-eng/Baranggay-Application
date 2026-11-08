package com.ibarangay.controller;

import com.ibarangay.model.Citizen;
import com.ibarangay.service.CitizenService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/citizens")
public class CitizenController {

    private final CitizenService service;

    public CitizenController(CitizenService service) {
        this.service = service;
    }

    // Retrieve all citizens
    @GetMapping
    public List<Citizen> getAll() {
        return service.getAllCitizens();
    }

    // Retrieve citizen by ID
    @GetMapping("/{citizenId}")
    public ResponseEntity<Citizen> getById(
            @PathVariable Long citizenId) {

        return service.getCitizenById(citizenId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Register a new citizen
    @PostMapping
    public ResponseEntity<Citizen> create(
            @RequestBody Citizen citizen) {

        citizen.setCreatedAt(LocalDateTime.now());

        Citizen saved = service.saveCitizen(citizen);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(saved);
    }

    // Update citizen information
    @PutMapping("/{citizenId}")
    public ResponseEntity<Citizen> update(
            @PathVariable Long citizenId,
            @RequestBody Citizen updatedCitizen) {

        return service.getCitizenById(citizenId)
                .map(existing -> {

                    existing.setFirstName(updatedCitizen.getFirstName());
                    existing.setMiddleName(updatedCitizen.getMiddleName());
                    existing.setLastName(updatedCitizen.getLastName());
                    existing.setDateOfBirth(updatedCitizen.getDateOfBirth());
                    existing.setAddress(updatedCitizen.getAddress());
                    existing.setContactNo(updatedCitizen.getContactNo());
                    existing.setEmail(updatedCitizen.getEmail());

                    Citizen saved = service.saveCitizen(existing);

                    return ResponseEntity.ok(saved);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete citizen
    @DeleteMapping("/{citizenId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long citizenId) {

        if (!service.citizenExists(citizenId)) {
            return ResponseEntity.notFound().build();
        }

        service.deleteCitizen(citizenId);

        return ResponseEntity.noContent().build();
    }
}