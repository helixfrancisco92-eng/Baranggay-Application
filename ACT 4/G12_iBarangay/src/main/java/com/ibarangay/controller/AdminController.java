package com.ibarangay.controller;

import com.ibarangay.model.Admin;
import com.ibarangay.service.AdminService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admins")
public class AdminController {

    private final AdminService service;

    public AdminController(AdminService service) {
        this.service = service;
    }

    // Retrieve all administrators
    @GetMapping
    public List<Admin> getAll() {
        return service.getAllAdmins();
    }

    // Retrieve administrator by ID
    @GetMapping("/{adminId}")
    public ResponseEntity<Admin> getById(
            @PathVariable Long adminId) {

        return service.getAdminById(adminId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create a new administrator
    @PostMapping
    public ResponseEntity<Admin> create(
            @RequestBody Admin admin) {

        Admin saved = service.saveAdmin(admin);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(saved);
    }

    // Update an existing administrator
    @PutMapping("/{adminId}")
    public ResponseEntity<Admin> update(
            @PathVariable Long adminId,
            @RequestBody Admin updatedAdmin) {

        return service.getAdminById(adminId)
                .map(existing -> {

                    existing.setFullName(updatedAdmin.getFullName());
                    existing.setUsername(updatedAdmin.getUsername());
                    existing.setRole(updatedAdmin.getRole());
                    existing.setActive(updatedAdmin.isActive());

                    Admin saved = service.saveAdmin(existing);

                    return ResponseEntity.ok(saved);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete an administrator
    @DeleteMapping("/{adminId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long adminId) {

        if (!service.adminExists(adminId)) {
            return ResponseEntity.notFound().build();
        }

        service.deleteAdmin(adminId);

        return ResponseEntity.noContent().build();
    }
}