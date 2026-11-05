package com.ridelog.server.record;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MaintenanceRecordService {

    private final MaintenanceRecordRepository repository;

    public List<RecordResponse> findAll(Category category) {
        List<MaintenanceRecord> list = (category == null)
                ? repository.findAllByOrderByServiceDateDescIdDesc()
                : repository.findByCategoryOrderByServiceDateDescIdDesc(category);
        return list.stream().map(RecordResponse::from).toList();
    }

    public RecordResponse findOne(Long id) {
        return RecordResponse.from(get(id));
    }

    @Transactional
    public RecordResponse create(RecordRequest req) {
        return RecordResponse.from(repository.save(new MaintenanceRecord(req)));
    }

    @Transactional
    public RecordResponse update(Long id, RecordRequest req) {
        MaintenanceRecord record = get(id);
        record.update(req);   // 변경 감지(dirty checking)로 자동 UPDATE
        return RecordResponse.from(record);
    }

    @Transactional
    public void delete(Long id) {
        repository.delete(get(id));
    }

    public SummaryResponse summary() {
        List<MaintenanceRecord> all = repository.findAll();
        long totalCost = all.stream().mapToLong(MaintenanceRecord::getCost).sum();
        int latestMileage = repository.findTopByOrderByMileageDesc()
                .map(MaintenanceRecord::getMileage)
                .orElse(0);

        List<SummaryResponse.NextService> next = new ArrayList<>();
        for (Category c : Category.values()) {
            if (c.getIntervalKm() == 0) continue;
            repository.findTopByCategoryOrderByMileageDesc(c).ifPresent(last -> {
                int nextMileage = last.getMileage() + c.getIntervalKm();
                next.add(new SummaryResponse.NextService(
                        c, c.getLabel(), last.getMileage(), nextMileage, nextMileage - latestMileage));
            });
        }
        return new SummaryResponse(all.size(), totalCost, latestMileage, next);
    }

    private MaintenanceRecord get(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("정비 기록을 찾을 수 없습니다. id=" + id));
    }
}
