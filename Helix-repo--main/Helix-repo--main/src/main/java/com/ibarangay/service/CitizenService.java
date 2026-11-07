package com.ibarangay.service;

import com.ibarangay.model.Citizen;
import com.ibarangay.repository.CitizenRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CitizenService {

    private final CitizenRepository citizenRepository;

    public CitizenService(CitizenRepository citizenRepository) {
        this.citizenRepository = citizenRepository;
    }

    // Retrieve all citizens
    public List<Citizen> getAllCitizens() {
        return citizenRepository.findAll();
    }

    // Retrieve citizen by ID
    public Optional<Citizen> getCitizenById(Long citizenId) {
        return citizenRepository.findById(citizenId);
    }

    // Register or update citizen
    public Citizen saveCitizen(Citizen citizen) {
        return citizenRepository.save(citizen);
    }

    // Delete citizen
    public void deleteCitizen(Long citizenId) {
        citizenRepository.deleteById(citizenId);
    }

    // Check whether citizen exists
    public boolean citizenExists(Long citizenId) {
        return citizenRepository.existsById(citizenId);
    }
}