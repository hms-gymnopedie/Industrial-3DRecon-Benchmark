# Citation Audit Report

> ARS `academic-paper` `citation-check` mode 산출물
> 생성일: 2026-05-12
> Target documents: [LIT_REVIEW.md](LIT_REVIEW.md) (ref list [1]~[29] + §2 본문), [PAPER_OUTLINE.md](PAPER_OUTLINE.md) (Evidence Map + 본문 LR-ref)
> Citation style: **IEEE** (numbered brackets, order of appearance)
> Verification sources: **CrossRef API** + **OpenAlex API** (이중 검증)

---

## 1. Summary

| Metric | Count |
|--------|-------|
| Total reference list entries | 29 |
| Total in-text citations (§2 draft) | 15 unique ([1]–[10], [18]–[21], [24]) |
| **Orphan in-text** (cited but missing in ref list) | 0 |
| Orphan in ref list (not cited in §2) | 14 — *all assigned in PAPER_OUTLINE downstream §1.2/§3/§4.4/§4.5/§5.2/§5.6, so non-orphan project-wide* |
| **Major fabrications (CRITICAL)** | 2 — 저자명 잘못 (auto-corrected) |
| **Major attribution errors** | 1 — §2.1 [25]→[24] (auto-corrected) |
| Format issues (flagged for review) | 4 |
| DOI completeness | 15/29 confirmed via CrossRef (보강 권장) |
| Self-citation ratio | 0% (해당 없음) |
| Sources from last 5 years (2021–) | 14/29 (48%) ✓ |

---

## 2. Tier 1 — Major Corrections (auto-applied)

### 2.1 [CRITICAL FABRICATION] [20] 저자명 잘못

| 항목 | 변경 전 (WebSearch 오인) | 변경 후 (CrossRef + OpenAlex 검증) |
|---|---|---|
| 저자 | A. Braun *et al.* | **J. Xue, X. Hou, Y. Zeng** |
| Title | (동일) | "Review of Image-Based 3D Reconstruction of Building for Automated Construction Progress Monitoring" |
| Venue | (동일) | *Applied Sciences*, vol. 11, no. 17, p. 7840, 2021 |
| DOI | (없음) | https://doi.org/10.3390/app11177840 |

**Decision tree classification:** Major (claim not in source — 저자 attribution 오류). Auto-corrected ☑
**Propagated to:** LIT_REVIEW §E [20] entry + §2.5 본문 + Evidence Map + [TBD] 표; PAPER_OUTLINE Evidence Map + Patch Log entry.

### 2.2 [CRITICAL FABRICATION] [21] 저자명 잘못

| 항목 | 변경 전 (WebSearch 오인) | 변경 후 (CrossRef + OpenAlex 검증) |
|---|---|---|
| 저자 | S. Jiang, D. Jiang, W. Jiang | **A. Sun, X. An, P. Li, M. Lv, W. Liu** |
| Title | (동일) | "Near Real-Time 3D Reconstruction of Construction Sites Based on Surveillance Cameras" |
| Venue | (동일) | *Buildings*, vol. 15, no. 4, p. 567, 2025 |
| DOI | (없음) | https://doi.org/10.3390/buildings15040567 |

**Decision tree classification:** Major (claim not in source — 저자 attribution 오류). Auto-corrected ☑
**Propagated to:** LIT_REVIEW §E [21] entry + §2.5 본문 + Evidence Map + [TBD] 표; PAPER_OUTLINE Evidence Map + Patch Log entry.

### 2.3 [MAJOR ATTRIBUTION] §2.1 본문 [25] → [24]

| 위치 | 변경 전 | 변경 후 |
|---|---|---|
| LIT_REVIEW.md §2.1 본문 | "keypoint repeatability가 붕괴되는 근본적 한계를 지닌다[25]" | "…근본적 한계를 지닌다[24]" |

**근거:** 기존 [25]는 renumbering 이전 Künsch89 (bootstrap statistics), renumbering 이후 Bergmann19 (MVTec AD anomaly detection)으로 둘 다 "hand-crafted feature 한계 in textureless area" claim과 무관. 올바른 ref는 [24] Romanoni & Matteucci, "TAPA-MVS: Textureless-Aware PAtchMatch Multi-View Stereo" (ICCV 2019). Auto-corrected ☑

---

## 3. Tier 2 — DOI 보강 권고 (auto-correctable)

CrossRef API로 검증된 추가 DOI를 ref list에 명시 권장. 현재 entries에는 venue/year만 있고 DOI 누락.

| Ref | Shorthand | DOI (CrossRef 검증) |
|---|---|---|
| [1] | Schönberger16 (COLMAP) | 10.1109/CVPR.2016.445 |
| [8] | Kerbl23 (3DGS) | 10.1145/3592433 |
| [9] | Huang24 (2DGS) | 10.1145/3641519.3657428 |
| [10] | Lowe04 (SIFT) | 10.1023/B:VISI.0000029664.99615.94 |
| [11] | Dai17 (ScanNet) | 10.1109/CVPR.2017.261 |
| [15] | Pertuz13 (focus measures) | 10.1016/j.patcog.2012.11.011 |
| [18] | Karaman11 (RRT*) | 10.1177/0278364911406761 |
| [19] | Bosché10 (industrial BIM) | 10.1016/j.aei.2009.08.006 |
| [22] | Verbin22 (Ref-NeRF) | 10.1109/CVPR52688.2022.00541 |
| [23] | Bescos18 (DynaSLAM) | 10.1109/LRA.2018.2860039 |
| [24] | Romanoni19 (TAPA-MVS) | 10.1109/ICCV.2019.01051 |
| [25] | Bergmann19 (MVTec AD) | 10.1109/CVPR.2019.00982 |
| [26] | Künsch89 (block bootstrap) | 10.1214/aos/1176347265 |
| [27] | Politis94 (stationary bootstrap) | 10.1080/01621459.1994.10476870 |
| [29] | Runeson09 (case study guidelines) | 10.1007/s10664-008-9102-8 |

**상태:** DOI 미반영. User pick 후 batch insert 가능 (15개 entries에 `doi: https://doi.org/...` 라인 추가).

### Tier 2 DOI 미확정 (arXiv-only 또는 추가 조회 필요)

| Ref | Shorthand | Status |
|---|---|---|
| [2] | Pan24 (GLOMAP) | arXiv:2407.20219 — ECCV 2024 proceedings DOI 추가 가능 |
| [3] | Wang24 (DUSt3R) | arXiv:2312.14132 — CVPR 2024 proceedings DOI 추가 가능 |
| [4] | Leroy24 (MASt3R) | arXiv:2406.09756 — ECCV 2024 proceedings DOI 추가 가능 |
| [5] | Teed21 (DROID-SLAM) | NeurIPS 2021 (no DOI assigned to NeurIPS proc.) |
| [6] | Lipson24 (DPV-SLAM) | arXiv:2408.01654 — ECCV 2024 proceedings DOI 추가 가능 |
| [7] | Murai25 (MASt3R-SLAM) | arXiv:2412.12392 — CVPR 2025 proceedings DOI 추가 가능 |
| [12] | Straub19 (Replica) | arXiv:1906.05797 only |
| [13] | Ravi24 (SAM2) | arXiv:2408.00714 only (preprint) |
| [14] | Jocher23 (YOLOv8) | GitHub release, no DOI |
| [16] | Kazhdan06 (Poisson) | SGP 2006 — DOI 검증 필요 |
| [17] | Guédon24 (SuGaR) | arXiv:2311.12775 / CVPR 2024 — DOI 추가 가능 |
| [28] | Wohlin12 (Experimentation in SE) | Springer book, ISBN 978-3-642-29044-2 — book DOI |

---

## 4. Tier 3 — Format Notes (review-only, no block)

### 4.1 IEEE proc. 표기 minor inconsistencies

| Ref | Note |
|---|---|
| [1] | "in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, Las Vegas, NV, 2016" — CVPR 2016은 "CVF joint" branding 이전. 엄밀하게는 "*Proc. IEEE Conf. CVPR*". 학술 reviewer 관용 허용 범위. **결정:** 유지 (style consistency 위해 [11] Dai17과 통일). |
| [8] | "*ACM Trans. Graphics (SIGGRAPH)*, vol. 42, no. 4, 2023" — ACM ToG의 정확한 표기는 article number 포함 (`art. 139`). 미미한 차이. |
| [9] | "in *Proc. ACM SIGGRAPH*, 2024" — SIGGRAPH 2024 Conf. Papers가 더 정확. |

### 4.2 저자명 transliteration

| Ref | Note |
|---|---|
| [1] | "J. L. Schönberger" — CrossRef는 umlaut 없는 "Schonberger" 등록. IEEE convention은 원 표기 (umlaut 포함) 유지. **유지.** |
| [26] | "H. R. Künsch" — 동일 패턴. **유지.** |

### 4.3 Runeson09 publication year

| Ref | Note |
|---|---|
| [29] | CrossRef metadata는 publication year=2008 (online first), 그러나 journal issue는 2009 vol. 14 no. 2. 학계 표준 인용은 **2009** (issue 기준). **현재 표기 유지.** |

---

## 5. Cross-Document Consistency Check

LIT_REVIEW.md ↔ PAPER_OUTLINE.md 사이 ref 번호 / shorthand label 일관성.

| Cross-check | Status |
|---|---|
| Evidence Map shorthand label match | ✅ Xue21·Sun25·Wohlin12·Runeson09 등 두 파일 일관 |
| LR-ref 번호 ([LR-N]) 두 파일 동기화 | ✅ §4.4 [LR-26]/[LR-27], §5.6 [LR-28]/[LR-29] 모두 정합 |
| Patch Log 4 entries → 6 entries (citation-check 2건 추가) | ✅ |
| Stale tokens ([LR-25], 후보 A/B, Braun, Jiang) | ✅ 모두 제거 (grep clean) |

---

## 6. Quality Gate Status

| Gate | Criterion | Result |
|---|---|---|
| Zero orphan in-text | 0 | ✅ Pass (0개) |
| Zero orphan ref (project-wide) | 0 | ✅ Pass — §2 본문 미인용 14개는 모두 PAPER_OUTLINE의 §1.2/§3/§4/§5에서 인용됨 |
| Format compliance rate | 100% | ⚠️ ~93% — Tier 3 minor 4건 검토 권장 |
| Fabrication / misattribution | 0 | ✅ Pass — 3건 모두 자동 정정 완료 |
| DOI completeness | All available | ⚠️ 15/29 검증, Tier 2에 보강 후보 명시 |
| Audit log | 100% | ✅ Pass — 이 report |

**Overall:** **Pass with Tier 2 보강 권장.** Tier 1 critical 모두 정정 완료. Tier 2 DOI 일괄 삽입은 user approval 후 진행.

---

## 7. Next-Step Options

```
[현재] CITATION_AUDIT.md 완료 ✅ (Tier 1 fabrication 3건 정정 완료)
   │
   ├─→ Option A: Tier 2 DOI 15건 batch insert (자동, ~5분)
   │
   ├─→ Option B: Tier 2 추가 DOI 검증 (GLOMAP/DUSt3R/MASt3R/DPV-SLAM/MASt3R-SLAM/SuGaR/Poisson/Wohlin book 등 8건)
   │
   ├─→ Option C: 그대로 두고 실험/본문 작성 트랙 진입 (DOI는 본문 final draft 단계에서 보강)
   │
   └─→ Option D: /ars-format-convert로 다른 citation style (APA/Chicago 등) 변환
```
