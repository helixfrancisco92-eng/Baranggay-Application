package com.ibarangay.service;

import com.ibarangay.model.Requirement;
import com.ibarangay.repository.RequirementRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RequirementService {

    private final RequirementRepository requirementRepository;

    public RequirementService(RequirementRepository requirementRepository) {
        this.requirementRepository = requirementRepository;
    }

    // Retrieve all requirements
    public List<Requirement> getAllRequirements() {
        return requirementRepository.findAll();
    }

    // Retrieve requirement by ID
    public Optional<Requirement> getRequirementById(Long requirementId) {
        return requirementRepository.findById(requirementId);
    }

    // Create or update requirement
    public Requirement saveRequirement(Requirement requirement) {
        return requirementRepository.save(requirement);
    }

    // Delete requirement
    public void deleteRequirement(Long requirementId) {
        requirementRepository.deleteById(requirementId);
    }

    // Check whether requirement exists
    public boolean requirementExists(Long requirementId) {
        return requirementRepository.existsById(requirementId);
    }
}