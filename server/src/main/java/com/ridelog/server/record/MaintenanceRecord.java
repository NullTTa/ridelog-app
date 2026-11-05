package com.ridelog.server.record;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 정비 기록 엔티티
 */
@Entity
@Table(name = "maintenance_record")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MaintenanceRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Category category;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false)
    private Integer mileage;      // 정비 당시 주행거리(km)

    @Column(nullable = false)
    private Integer cost;         // 비용(원)

    @Column(nullable = false)
    private LocalDate serviceDate;

    @Column(length = 100)
    private String shop;          // 정비소

    @Column(length = 500)
    private String memo;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public MaintenanceRecord(RecordRequest req) {
        apply(req);
    }

    public void update(RecordRequest req) {
        apply(req);
    }

    private void apply(RecordRequest req) {
        this.category = req.category();
        this.title = req.title();
        this.mileage = req.mileage();
        this.cost = req.cost();
        this.serviceDate = req.serviceDate();
        this.shop = req.shop();
        this.memo = req.memo();
    }

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
