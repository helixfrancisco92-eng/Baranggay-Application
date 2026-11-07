package com.ibarangay.service;

import com.ibarangay.model.Admin;
import com.ibarangay.repository.AdminRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AdminService {

    private final AdminRepository adminRepository;

    public AdminService(AdminRepository adminRepository) {
        this.adminRepository = adminRepository;
    }

    // Retrieve all administrators
    public List<Admin> getAllAdmins() {
        return adminRepository.findAll();
    }

    // Retrieve administrator by ID
    public Optional<Admin> getAdminById(Long adminId) {
        return adminRepository.findById(adminId);
    }

    // Create or update administrator
    public Admin saveAdmin(Admin admin) {
        return adminRepository.save(admin);
    }

    // Delete administrator
    public void deleteAdmin(Long adminId) {
        adminRepository.deleteById(adminId);
    }

    // Check whether administrator exists
    public boolean adminExists(Long adminId) {
        return adminRepository.existsById(adminId);
    }
}