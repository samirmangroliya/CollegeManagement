package com.my.collegemanagement.repository;

import com.my.collegemanagement.constants.Role;
import com.my.collegemanagement.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Spring generates the SQL automatically from method names!

    Optional<User> findByEmail(String email);
    // → SELECT * FROM users WHERE email = ?

    Boolean existsByEmail(String email);
    // → SELECT COUNT(*) FROM users WHERE email = ?

    List<User> findByRole(Role role);
    // → SELECT * FROM users WHERE role = ?

    List<User> findByIsActiveTrue();
    // → SELECT * FROM users WHERE is_active = true
}