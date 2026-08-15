package com.my.collegemanagement.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class APIController {

    @GetMapping({"/", "/health"})
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Server is running. API is accessible now",
            "data", Map.of(
                "service", "College Management System",
                "version", "1.0.0"
            )
        ));
    }

    @GetMapping({"/users"})
    public ResponseEntity<Map<String, Object>> users() {
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Users list fetched successfully...",
            "data", Map.of(
                "User", "John Doe",
                "address", "123 Main St, Anytown, USA"
            )
        ));
    }
}