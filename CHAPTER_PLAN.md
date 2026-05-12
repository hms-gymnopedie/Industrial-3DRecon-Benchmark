# Chapter Plan + INSIGHT Collection

> ARS Plan Mode 산출물
> 생성일: 2026-05-11
> 모드: `academic-paper` → `plan` (Socratic chapter-by-chapter)
> **rev2 (2026-05-11):** Cluster 명명 A/C/D → **A/B/C**로 sync (PAPER_OUTLINE.md rev2와 정합). 의미 보존: B = Scene Non-staticity (구 C), C = Photometric Drift (구 D).

---

## 0. Paper Configuration

| 항목 | 값 |
|---|---|
| **국문 제목** | 산업현장 보디캠 영상 기반 3D 재구성 파이프라인 개발 및 로봇 자율주행 활용을 위한 비교 평가 |
| **영문 제목 (가안)** | Development of a Body Camera-Based 3D Reconstruction Pipeline for Industrial Sites: A Comparative Evaluation toward Robot Autonomous Navigation |
| **Paper Type** | Systems paper (Engineering) — 파이프라인 개발 + 비교평가 hybrid |
| **목표 저널** | KCI 등재 공학 저널 (구체 후보 미정) |
| **인용 형식** | IEEE |
| **출력 포맷** | LaTeX + DOCX |
| **언어** | 본문 한국어 / Abstract 한·영 bilingual |
| **목표 분량** | 본문 ~6,150 단어 + Abstract/References ~1,800 단어 ≈ **8,000–10,000 단어 (8–12 page)** |
| **Oversight Level** | Very-high (plan mode) → 다음 단계 High (outline mode) |

---

## 1. INSIGHT Collection

### INSIGHT 1 — Thesis Statement (v1.1)

> **산업현장 도메인에서는** 학습 기반 deep-prior pose estimation(예: MASt3R-SLAM, DPV-SLAM)과 평면 사전(planar prior) 기반 표현(예: 2DGS)이 결합된 파이프라인이, hand-crafted feature 기반 SfM(예: COLMAP, GLOMAP) + 일반 3D Gaussian(3DGS) 파이프라인에 비해 **재구성 강건성**과 **로봇 자율주행 적합성**(point-cloud / mesh 추출, BEV occupancy 변환) 양면에서 우위를 보이며, **그 격차(Δ_industrial)는 일반 실내 도메인(library control)에서의 격차(Δ_library)에 비해 통계적으로 유의하게 증폭된다.**

**Reframing 이력:**
- v1.0 ("SLAM > SfM") → v1.1 ("deep prior > hand-crafted feature") 로 메커니즘 정합성 향상
- BEV는 baseline이 아닌 **post-processing step** (orthographic projection + occupancy grid)

**반대 입장 (Devil's advocate):**
- 산업현장도 hand-crafted feature가 충분한 영역이 있다 → §4.5 textureless-region ablation으로 반박
- Gap은 hyperparameter 튜닝의 차이일 뿐이다 → §3.4 fairness protocol (동일 GPU, 동일 epoch budget, default config)
- 9개 baseline 중 cherry-picking이다 → §1.4에서 H-Best / H-Worst를 **pre-register**

---

### INSIGHT 2 — Pre-registered Hypotheses

post-hoc dispute 방지 목적. §1.4 또는 §3.5에서 명시적으로 선언.

| Hypothesis | 내용 | 검증 위치 |
|---|---|---|
| **H-Best** | 9개 baseline 중 산업현장에서 가장 우수한 조합 = **MASt3R-SLAM + 2DGS** | §4.3, §4.4 |
| **H-Worst** | 가장 열위인 조합 = **COLMAP + 3DGS** (특히 dynamic + low-light scene) | §4.3, §4.4 |
| **H-Gap** | Industrial Δ (Best − Worst) > Library Δ (Best − Worst), p < 0.05 | §4.4, §5.1 |
| **H-Mechanism** | 3개 mechanism cluster (A/B/C) 각각에서 deep-prior 계열이 hand-crafted 계열보다 강건 | §4.5 ablation |

**의의:** 결과가 H를 지지하지 않을 경우(특히 H-Gap fail)에도 paper는 성립 — "산업/일반 격차가 예상보다 작다"는 negative finding 자체가 contribution.

---

### INSIGHT 3 — Mechanism Three Clusters

산업현장 difficulty를 3개 인과 cluster로 분류. §3.5 (도메인 분석) + §4.5 (ablation) 양쪽에서 사용.

| Cluster | 명칭 | 구성 요소 | 영향 받는 모듈 |
|---|---|---|---|
| **A** | Visual Ambiguity | textureless (콘크리트/벽), reflective (금속 외관), 오염 (먼지/페인트 박리) | Feature matching, depth prior |
| **B** | Scene Non-staticity | dynamic objects (작업자/자재), scale 변동 (근/원경 혼재) | Pose estimation, multi-view consistency |
| **C** | Photometric Drift | low-light, 그림자, 비균질 조명 | Photometric loss, color consistency |

**Library control 매칭:** Library 도메인은 A·B·C 모든 cluster에서 산업현장보다 약함 → Δ 비교 정당화.

---

## 2. Contributions

| ID | 분류 | 내용 |
|---|---|---|
| **C1** | 비교평가 (β) | **9-method comparison evaluation** — SfM 계열 (COLMAP, GLOMAP) × Deep SLAM 계열 (DPV-SLAM, DROID-SLAM, MASt3R-SLAM) × Learning matching (DUSt3R, MASt3R) × Representation (2DGS, 3DGS) on industrial + library domains |
| **C2** | 시스템 (γ) | **End-to-end pipeline** — capture → preprocessing → camera mapping → 3D reconstruction → BEV → IsaacSim → robot navigation |
| **C3** | 디자인 원칙 (δ) | **Domain-method matching design principle** — 산업현장 도메인에는 deep-prior + planar-prior representation 조합이 추천된다는 actionable 가이드라인 |
| C2-sub-a | 서브 | Preprocessing module (fps/sharpness filtering, masking auto) — *구현 완료* |
| C2-sub-b | 서브 | Evaluation harness (9 baseline 자동 비교 스크립트) |
| C2-sub-c | 서브 | BEV + IsaacSim 연동 (Spot + RRT* navigation test) |

**Thesis는 C1+C2 중심 (β+γ), C3은 결론 단계 actionable take-away.**
**α(전처리 모듈) = "Option I-soft" — §3에서 structural contribution으로 argue하되 thesis-level claim에는 포함시키지 않음.**

---

## 3. Chapter Structure (총 ~8,000–10,000 단어)

```
§1 Introduction              ~800 단어
§2 Related Work              ~900 단어
§3 Pipeline Design           ~1,400 단어
§4 Experiments               ~1,700 단어
§5 Discussion                ~1,100 단어
§6 Conclusion                ~250 단어
─────────────────────────────────────
본문 소계                     ~6,150 단어
Abstract (KR+EN) +
References + Appendix        ~1,800 단어
─────────────────────────────────────
총합                          ~8,000–10,000 단어
```

---

## 4. Chapter Summaries

### §1 Introduction (~800 단어)

**Goal:** 산업현장 robot autonomy를 위한 3D recon의 도메인-특화적 어려움과, 그것이 일반 도메인 벤치마크에서 가려져 있다는 gap을 설득.

**핵심 흐름:**
1. **Hook** — 산업현장 자율주행 로봇 수요 증가 (스마트팩토리, 위험구역 점검, 시설관리)
2. **Tension** — 기존 3D recon 벤치마크는 대부분 ScanNet, Replica, KITTI 등 정돈된/실외 도메인 → 산업현장 적용 시 강건성 검증 부재
3. **Research Gap** — 다음 한 문장:
   > "산업현장 보디캠 영상을 입력으로 9개의 최신 3D recon 파이프라인을 일관된 protocol로 비교 평가하고, 그 결과를 로봇 자율주행 task에 연결한 연구는 아직 존재하지 않는다."
4. **Contributions (C1–C3)** — bullet 형식
5. **Pre-registered claims (H-Best, H-Worst, H-Gap)** — *방어선*
6. **Paper roadmap** — §2~§6 한 줄 요약

**Reader가 이 챕터를 읽고 가져야 할 sense of urgency:** "산업현장은 일반 도메인과 다르고, 그 다름이 method choice에 영향을 미친다"

---

### §2 Related Work (~900 단어)

**Goal:** 9개 baseline의 계보학적 정리 + 산업현장 도메인 연구 부재 부각.

**Sub-sections:**
- **§2.1 Structure-from-Motion** — COLMAP[hand-crafted], GLOMAP[global] 계열, 산업현장 적용 사례 미흡
- **§2.2 Learning-based Matching** — DUSt3R, MASt3R (pairwise dense matching)
- **§2.3 Deep SLAM** — DROID-SLAM, DPV-SLAM, MASt3R-SLAM (end-to-end pose + map)
- **§2.4 3D Representations** — 3DGS (general Gaussian), 2DGS (planar prior)
- **§2.5 Industrial / Cluttered Domain Reconstruction** — 기존 industrial point cloud 연구는 LiDAR 기반 → camera-only 격차
- **§2.6 Robot Navigation from Reconstructed Maps** — BEV/occupancy 변환 관련 prior work

**Literature 충돌 지점 (논쟁 자료):** "COLMAP은 모든 도메인에서 충분히 강건하다"는 광범위 통념 → 본 연구가 반박할 지점

---

### §3 Pipeline Design (~1,400 단어)

**Goal:** End-to-end pipeline 구조 + 산업현장 도메인 특성 → method 선택 근거 → fairness protocol.

**Sub-sections:**
- **§3.1 Pipeline Overview** — 다이어그램 1장 (capture → preprocess → camera mapping → 3D recon → BEV → IsaacSim → nav)
- **§3.2 Preprocessing Module** *(C2-sub-a; α structural contribution)* — fps filtering, sharpness threshold, masking automation
- **§3.3 Camera Mapping Stage** — 9 baseline 어디까지 포함되는지 ablation matrix
- **§3.4 3D Representation Stage** — 2DGS vs 3DGS 결합 시나리오
- **§3.5 Industrial Domain Characteristics + Mechanism Clusters (A/B/C)** — INSIGHT 3 fully unpacked
- **§3.6 Fairness Protocol** — 동일 GPU, 동일 max epoch / iteration budget, default hyperparameter, 전처리 동일 적용
- **§3.7 BEV + IsaacSim Integration** *(C2-sub-c)* — orthographic projection 알고리즘, IsaacSim import workflow

**Defense 포인트:**
- "Why not LiDAR fusion?" → 본 연구의 scope = camera-only, body-worn 환경 제약
- "Why these 9 baselines?" → SfM ↔ Deep SLAM ↔ Learning matching ↔ Representation 4계열을 cover하기 위한 minimal complete set

---

### §4 Experiments (~1,700 단어)

**Goal:** Pre-registered hypotheses (H-Best, H-Worst, H-Gap, H-Mechanism) 검증 + ablation으로 mechanism causality 입증.

**Sub-sections:**

- **§4.1 Datasets** — Industrial: 3 sites × 5min videos (총 ~15min) / Library control: 3 sites × 1–2min videos
- **§4.2 Metrics** —
  - *Reconstruction quality*: PSNR, SSIM, LPIPS, Chamfer Distance
  - *Robot navigation suitability*: BEV occupancy IoU (vs ground-truth), RRT* success rate in IsaacSim, path length, collision count
  - *Efficiency*: GPU memory peak, wall-clock time per scene

- **§4.3 Main Result — 9 baseline × 2 domain comparison table**

- **§4.4 H-Gap test** — Statistical test (paired) on Δ_industrial vs Δ_library

- **§4.5 Mechanism Ablation (가장 risky한 부분, 강화 설계)**
  - **§4.5a Stage 0 — Pilot study** (1 site, 2 method): textureless mask가 method 성능에 측정 가능한 영향을 주는지 사전 확인. 실패 시 §4.5b–d 재설계.
  - **§4.5b Textureless region ablation** — Cluster A 효과 격리
  - **§4.5c Reflective region ablation** — Cluster A의 sub-component
  - **§4.5d 오염 region ablation** — Cluster A의 sub-component (3-parallel ablation, redundant by design)
  - **§4.5e Dynamic object removal ablation** — Cluster B 효과 격리
  - **§4.5f Low-light gamma adjustment ablation** — Cluster C 효과 격리

- **§4.6 Robot Navigation Evaluation (IsaacSim + Spot + RRT*)** — 9 reconstructed maps × navigation task success rate

**Risk monitoring:**
- 최대 위험: §4.5b textureless ablation이 effect size 너무 작아 mechanism causality 입증 실패 → mitigation: 3-parallel ablation (textureless + reflective + 오염) 으로 Cluster A를 redundant하게 측정 + Stage 0 pilot으로 사전 검증

---

### §5 Discussion (~1,100 단어)

**Goal:** Results를 literature와 dialogue + actionable design principle (C3) 도출 + limitations.

**Sub-sections:**
- **§5.1 H 검증 결과 요약** — Best/Worst/Gap/Mechanism 각각 supported/partial/refuted 명시
- **§5.2 Why deep prior > hand-crafted in industrial domain?** — Mechanism cluster별 해석
- **§5.3 Why 2DGS > 3DGS in industrial domain?** — planar prior가 산업현장의 벽/바닥 dominant geometry와 정합
- **§5.4 Design Principle (C3)** — "산업현장 robot autonomy를 위한 3D recon 파이프라인은 deep-prior pose + planar representation 조합을 기본으로 채택할 것"
- **§5.5 Limitations** — 3-site 한계, weather/season 미반영, real-world deployment 미검증
- **§5.6 Threats to Validity** — fairness protocol 한계, hyperparameter 민감도 unexplored 부분

**Reader가 가장 기억해야 할 한 문장:**
> "도메인의 mechanism(textureless·dynamic·photometric)을 식별하고, 그 mechanism에 견디는 prior를 가진 method를 매칭하는 것이 일반화된 벤치마크 점수보다 더 신뢰할 만한 method 선택 기준이다."

---

### §6 Conclusion (~250 단어)

**Goal:** 압축된 한 문단으로 가장 중요한 메시지 + 다음 연구 방향.

**핵심 흐름:**
1. Restate gap & contribution (1–2 문장)
2. 가장 중요한 finding: H-Gap 검증 결과 한 줄
3. C3 design principle 재강조
4. **Future work:**
   - Outdoor industrial sites (건설현장, 야외 플랜트) 확장
   - Multi-modal fusion (camera + IMU + LiDAR opportunistic)
   - On-device real-time deployment 검증
   - Long-term temporal consistency (월 단위 site change tracking)

---

## 5. Argument Stress Test 결과

| Sub-argument | 가장 약한 지점 | 대응 |
|---|---|---|
| H-Best (MASt3R-SLAM + 2DGS) | hyperparameter cherry-pick 의심 | §3.6 fairness protocol + default config 사용 명시 |
| H-Gap (Δ_industrial > Δ_library) | n=3 sites만으로 statistical power 부족 | per-frame bootstrap 또는 per-segment paired test로 effective sample size 증대 |
| H-Mechanism (cluster A 효과) | textureless 정의의 주관성 | mask 생성 알고리즘 코드 공개 + 정량적 threshold (gradient magnitude) 명시 |
| C3 design principle | n=3 산업현장으로 일반화 가능한가 | §5.5 limitations에 명시적 한계 선언 + future work outdoor 확장 |
| BEV occupancy IoU | ground-truth occupancy 어떻게 정의? | manual annotation + Spot SLAM 결과를 reference로 활용 (inter-annotator agreement 보고) |

**역방향 (Reverse) 시나리오:** 만약 결과가 "SfM/GLOMAP이 산업현장에서도 충분히 강건하다"로 나오면? → paper 여전히 성립. "산업현장 difficulty가 method choice를 sensitive하게 만들지는 않는다"는 negative finding을 §5에서 보고. 이 경우 C3는 "단순한 SfM도 산업현장 robot map에 사용 가능"으로 reframe.

---

## 6. Risk Monitoring

| Risk | Severity | Mitigation |
|---|---|---|
| Textureless ablation effect size 부족 | **High** | Stage 0 pilot + 3-parallel ablation (textureless/reflective/오염) |
| n=3 sites statistical power | High | per-frame bootstrap, per-segment paired test |
| 9 baseline 일부가 산업현장 영상에서 학습 시 OOM/crash | Medium | fallback table (실행 불가 시 'N/A' 명시) + 이유 보고 |
| IsaacSim navigation success rate가 reconstruction quality와 약한 상관 | Medium | metric을 BEV occupancy IoU와 navigation success rate 둘 다 보고하여 robust |
| KCI reviewer가 "왜 LiDAR 없이?"라고 challenge | Low | §3 scope 명시 + body-worn 환경 제약 |
| Hyperparameter 공정성 dispute | Low | default config + tuning budget 동일 + 코드 공개 |

---

## 7. Next-Step Roadmap

```
[현재] Chapter Plan + INSIGHT Collection 완료 ✓
   │
   ├─→ /ars-outline (현재 단계: 상세 섹션·서브섹션 outline + evidence map)
   │      │
   │      └─→ 본문 작성 단계 (/ars-full 또는 수동)
   │
   ├─→ /ars-lit-review (병렬: §2 Related Work를 위한 annotated bibliography)
   │
   ├─→ 실험 단계 (9 baseline × 2 domain 실행, §4 결과 산출)
   │
   └─→ /ars-abstract (최종 단계, 본문 확정 후)
```

**현재 권장 경로:**
- **Path A (병렬):** 실험 진행 + /ars-lit-review 동시
- **Path B (직렬):** /ars-outline → 실험 → 본문 작성

---

## Appendix: Plan-Mode Negotiation Log Summary

총 6개 챕터 negotiation 완료. 주요 의사결정:

| # | 의사결정 | 채택안 |
|---|---|---|
| 1 | Title vs Contribution vs Structure 3-way 충돌 | Hybrid: β+γ contribution, systems paper structure, title 유지 |
| 2 | BEV를 baseline으로 포함? | post-processing step으로 재정의 (baseline 아님) |
| 3 | Thesis: "SLAM > SfM" | "deep prior > hand-crafted feature" 로 mechanism 정합화 |
| 4 | Library control 역할 | 단순 비교 → predictive mechanism test 로 격상 |
| 5 | 전처리 모듈(α) 기여 인정 | "Option I-soft" — §3 structural argue, thesis 미포함 |
| 6 | 9 baseline 중 cherry-pick 우려 | H-Best/H-Worst 사전 등록으로 사후 dispute 차단 |
| 7 | Textureless ablation 실패 위험 | Stage 0 pilot + 3-parallel ablation |
| 8 | Reviewer fairness dispute | hyperparameter + 전처리 공정성을 §3.6 단일 protocol로 통합 |
