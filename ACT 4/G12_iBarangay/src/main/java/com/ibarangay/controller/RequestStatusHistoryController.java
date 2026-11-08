package com.ibarangay.controller;

import com.ibarangay.model.RequestStatusHistory;
import com.ibarangay.service.RequestStatusHistoryService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/request-status-history")
public class RequestStatusHistoryController {

    private final RequestStatusHistoryService service;

    public RequestStatusHistoryController(
            RequestStatusHistoryService service) {
        this.service = service;
    }

    // Retrieve all request status history
    @GetMapping
    public List<RequestStatusHistory> getAll() {
        return service.getAllHistory();
    }

    // Retrieve a specific history record
    @GetMapping("/{historyId}")
    public ResponseEntity<RequestStatusHistory> getById(
            @PathVariable Long historyId) {

        return service.getHistoryById(historyId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Retrieve status history for a specific document request
    @GetMapping("/by-request/{requestId}")
    public List<RequestStatusHistory> getByRequestId(
            @PathVariable Long requestId) {

        return service.getHistoryByRequestId(requestId);
    }
}