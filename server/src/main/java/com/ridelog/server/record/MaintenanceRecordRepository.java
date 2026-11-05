package com.ridelog.server.record;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MaintenanceRecordRepository extends JpaRepository<MaintenanceRecord, Long> {

    List<MaintenanceRecord> findAllByOrderByServiceDateDescIdDesc();

    List<MaintenanceRecord> findByCategoryOrderByServiceDateDescIdDesc(Category category);

    Optional<MaintenanceRecord> findTopByOrderByMileageDesc();

    Optional<MaintenanceRecord> findTopByCategoryOrderByMileageDesc(Category category);
}
