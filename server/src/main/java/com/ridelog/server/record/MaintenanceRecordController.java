package com.ridelog.server.record;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class MaintenanceRecordController {

    private final MaintenanceRecordService service;

    /** 정비 기록 목록 (category 파라미터로 필터) */
    @GetMapping("/records")
    public List<RecordResponse> list(@RequestParam(required = false) Category category) {
        return service.findAll(category);
    }

    /** 정비 기록 상세 */
    @GetMapping("/records/{id}")
    public RecordResponse detail(@PathVariable Long id) {
        return service.findOne(id);
    }

    /** 정비 기록 등록 */
    @PostMapping("/records")
    public ResponseEntity<RecordResponse> create(@Valid @RequestBody RecordRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(req));
    }

    /** 정비 기록 수정 */
    @PutMapping("/records/{id}")
    public RecordResponse update(@PathVariable Long id, @Valid @RequestBody RecordRequest req) {
        return service.update(id, req);
    }

    /** 정비 기록 삭제 */
    @DeleteMapping("/records/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    /** 요약(총 건수, 총 비용, 다음 정비 예정) */
    @GetMapping("/summary")
    public SummaryResponse summary() {
        return service.summary();
    }

    /** 분류 목록 (앱 드롭다운용) */
    @GetMapping("/categories")
    public List<Map<String, Object>> categories() {
        return Arrays.stream(Category.values())
                .map(c -> Map.<String, Object>of(
                        "code", c.name(),
                        "label", c.getLabel(),
                        "intervalKm", c.getIntervalKm()))
                .toList();
    }
}
