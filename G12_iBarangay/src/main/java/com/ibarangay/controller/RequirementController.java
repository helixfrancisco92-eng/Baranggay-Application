package com.ibarangay.controller;

import com.ibarangay.model.Requirement;
import com.ibarangay.service.RequirementService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/requirements")
public class RequirementController {

    private final RequirementService service;

    public RequirementController(RequirementService service) {
        this.service = service;
    }

    // Retrieve all requirements
    @GetMapping
    public List<Requirement> getAll() {
        return service.getAllRequirements();
    }

    // Retrieve requirement by ID
    @GetMapping("/{requirementId}")
    public ResponseEntity<Requirement> getById(
            @PathVariable Long requirementId) {

        return service.getRequirementById(requirementId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create a new requirement
    @PostMapping
    public ResponseEntity<Requirement> create(
            @RequestBody Requirement requirement) {

        Requirement saved = service.saveRequirement(requirement);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(saved);
    }

    // Update an existing requirement
    @PutMapping("/{requirementId}")
    public ResponseEntity<Requirement> update(
            @PathVariable Long requirementId,
            @RequestBody Requirement updatedRequirement) {

        return service.getRequirementById(requirementId)
                .map(existing -> {

                    existing.setName(updatedRequirement.getName());
                    existing.setDescription(updatedRequirement.getDescription());
                    existing.setActive(updatedRequirement.isActive());

                    Requirement saved =
                            service.saveRequirement(existing);

                    return ResponseEntity.ok(saved);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete a requirement
    @DeleteMapping("/{requirementId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long requirementId) {

        if (!service.requirementExists(requirementId)) {
            return ResponseEntity.notFound().build();
        }

        service.deleteRequirement(requirementId);

        return ResponseEntity.noContent().build();
    }
}