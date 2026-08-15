package com.my.collegemanagement.entity;

import com.my.collegemanagement.constants.Role;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data                   // ← Lombok: generates getters, setters, toString
@Builder                // ← Lombok: User.builder().email("x").build()
@NoArgsConstructor      // ← Lombok: empty constructor (required by JPA)
@AllArgsConstructor     // ← Lombok: constructor with all fields
@Entity                 // ← JPA: this class maps to a DB table
@Table(name = "users")  // ← JPA: table name is "users"
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;       // stored as bcrypt hash — never plain text

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    private String phone;

    @Enumerated(EnumType.STRING)   // ← stores "ADMIN" not 0,1,2 in DB
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}