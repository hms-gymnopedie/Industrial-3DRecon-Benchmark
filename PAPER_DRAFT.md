# 산업현장 보디캠 영상 기반 3D 재구성 파이프라인 개발 및 로봇 자율주행 활용을 위한 비교 평가

> ARS `academic-paper` `write` mode 산출물
> 생성일: 2026-05-12
> Upstream: [PAPER_OUTLINE.md](PAPER_OUTLINE.md) (rev2 승인)
> Reference list: [LIT_REVIEW.md](LIT_REVIEW.md)
> Citation style: **IEEE numeric** (`[N]`)
> Figure/Table 정책: `[Fig. N: caption]` / `[Tab. N: caption]` placeholder (실제 이미지/렌더링은 결과 산출 후)
> Oversight: **High** / Spectrum: **Fidelity**

---

## Draft Log

| 일자 | 패치 | 영향 섹션 |
|---|---|---|
| 2026-05-12 | §3 Pipeline Design 초안 — PAPER_OUTLINE rev2 §3.1–§3.7 구조 그대로, IEEE numeric inline, Fig./Tab./Alg. placeholder | §3 |
| 2026-05-12 | §4 Experiments 초안 — §4.1–§4.6, 사전등록 가설 H-Best/H-Worst/H-Gap/H-Mechanism 명시, 수치 자리는 `(TBD)` placeholder, block bootstrap [26] / Wilcoxon · cluster A/B/C ablation · RRT* navigation 1,080 runs 설계 포함 | §4 |
| 2026-05-12 | §5 Discussion 초안 — §5.1 H-verdict Tab.4, §5.2 Why Deep>Hand-crafted (cluster A/B/C mechanism), §5.3 Why 2DGS>3DGS planar prior, §5.4 C3 design principle box, §5.5 Limitations, §5.6 Wohlin12 [28] / Runeson09 [29] validity framework | §5 |
| 2026-05-12 | §6 Conclusion 초안 — §6.1 Summary (gap + C1/C2/C3 + H-Gap finding 한 줄), §6.2 Future Work (outdoor / multi-modal / on-device / long-term / multi-robot) | §6 |
| 2026-05-12 | §1 Introduction 초안 — §1.1 Background (camera-only 산업현장 autonomy demand) / §1.2 Problem (ScanNet [11] · Replica [12] 일반 벤치마크 insufficient) / §1.3 Gap (single-sentence + 3 sub-gap) / §1.4 Contributions C1+C2+C3 + 4 사전등록 H / §1.5 Roadmap | §1 |
| 2026-05-12 | §2 Related Work 초안 — §2.1 SfM ([1][2][10]) / §2.2 Learning matching ([3][4]) / §2.3 Deep SLAM ([5][6][7]) / §2.4 3DGS vs 2DGS ([8][9]) / §2.5 Industrial / cluttered ([19][20][21]) / §2.6 Nav from recon ([18]) / §2.7 Synthesis (4-way intersection) | §2 |
| 2026-05-12 (revision pass — Tier 1+2) | Severity-tiered audit fix 7건 — **T1.1** §1.4 H-Mechanism narrow (P9 vs P1 representative 만 ablation 검증, deep-prior 전체 일반화는 §5.2 mechanism 해석으로 분리). **T1.2** §4.4 block bootstrap convention 정정 (비중첩 → Künsch overlapping moving-block). **T1.3** §3.7 stage 번호 충돌 해소 (Stage 0/1/2/3 → 5a/5b/6a/6b; §3.1 6-stage 와 정렬). **T2.1** §3.7 sparse Poisson [16] 사용 위치 명시 (실험 대상 아닌 future-work reference slot 임을 명시). **T2.2** §4.5e Cluster B.2 (scale 변동) ablation 미포함 disclaimer 추가. **T2.3** §4.2 Chamfer reference mesh 정의 명확화 (library: P9 mesh = low-bar reference / industrial: configuration-pair CD matrix = diagnostic only). **T2.4** §4.5e mask on/off wording 명시화. | §1.4, §3.7, §4.2, §4.4, §4.5e |
| 2026-05-12 (References import) | LIT_REVIEW.md IEEE refs [1]–[29] → PAPER_DRAFT.md References section import. Inline / refs mapping 100% (orphan 0 / unused 0 / gap 0). | References |
| 2026-05-12 (citation-check fix) | Audit 후 3-fix patch — **C1.1** §4.5c [22] claim-evidence mismatch 정정 (HSV detection → "standard image-processing primitive" 로 attribution 정정, Ref-NeRF [22] 인용은 두 번째 문장의 view-dependent specular 모델링 claim 으로만 유지). **C2.1** §3.7 sub-stage 5a "Huang et al. [9] §3.3 TSDF" 의 section number 제거 (검증 불가). **C2.2** [5] DROID-SLAM 에 arXiv:2108.10869 추가 (NeurIPS 2021 entry 통일성). | §3.7, §4.5c, [5] |
| 2026-05-13 (§3.2 4-sub-stage 갱신) | 사용자 video-to-image 전처리 모듈이 5 기능 (비디오 불러오기 / frame 나누기 / blur 자동삭제 / 유사도 기준 중복제거 / masking 처리) 사전 통합 사실 반영. **§3.2** 본문 3 sub-stage → 4 sub-stage 재구성: (a) Frame extraction (FPS) / (b) Sharpness-based blur removal [15] / (c) **Similarity-based deduplication (신규)** / (d) Masking automation [13][14]. Sub-stage (c) 는 보디캠 정지·저속 구간의 visually redundant frame 제거로 두 도메인의 effective information density 정규화 기여. **Alg. 1 pseudocode** 4-stage 로 갱신. **§3.6 F4** frame budget 1,500 정의를 "sub-stage (a)–(c) 통과 후 effective frame 수" 로 명시. **§3.6 F5 공개 commitment** 에 사용자 모듈 hyperparameter 포함 명시. | §3.2, §3.6 F4·F5 |
| 2026-05-13 (§3.2 정밀 사양 5-위치 일괄) | 사용자 video-to-image 모듈 상세 사양 (FFmpeg aspect-lock crop, 4-bucket {sharp/blur/drop/dup} 분류, 8×8 dHash + Hamming dedup, SAM 2.1 / SAM 3 unified backend, human-in-the-loop React+MUI dashboard, binary exclusion mask semantics) 을 5 위치 일괄 반영. **§3.2** 4 sub-stage → 4 sub-stage + (e) human-in-the-loop verification 정밀화 (SAMEngine facade · point/video-propagation/text-prompt 3-mode · Grounded-SAM 2 / SAM 3 native PCS · 가역적 reclassification · standard output layout `<scene>/{sharp,blur,drop,dup,masks,mask_preview}/`). **Alg. 1** 5-stage 로 갱신. **§4.5e** primary mask = SAM 2.1 / SAM 3 [13], secondary = YOLOv8-seg [14] cross-method check. **§5.5 L7 신규** — human-in-the-loop reclassification reproducibility 한계 + audit trail manifest 공개 commitment. **§5.6 Internal validity** SAM 2.1/SAM 3 vs YOLO IoU 명시 + L7 second-order 영향 언급. **§6.1 C2 summary** preprocess 부분을 정확한 6-component (FFmpeg / Laplacian 4-bucket / dHash / SAM 2/3 + YOLO sensitivity / dashboard) 로 갱신. | §3.2·§4.5e·§5.5·§5.6·§6.1 |
| 2026-05-13 (skip_empty mask 정책 정합 4-위치) | 사용자 모듈의 skip_empty 정책 (`len(masks) ≤ len(sharp)`, M ⊆ S; dynamic instance 검출 0건 frame 의 mask 미생성) 을 4 위치 일관 명시. **§3.2 (d)** skip_empty 정책 explicit statement 추가 + mask on/off condition 정의를 "mask 가 있는 frame 의 mask 영역만 제외; mask 없는 frame 은 그대로 학습 포함" 으로 정밀화. **§4.5e** ablation 의 **full-set comparison 정의** 명시 (S 전체, |M| / |S| 비율 부수 column 보고, mask-noise attenuation bias 가 §5.6 internal validity 로 흡수). **data/README.md §2** subset 관계 + ablation N/A 처리 (mask 전체 0개 site 시 row N/A) 명시. **data/README.md §5** 1:1 wording → subset wording 정정. **RUN_PILOT.md §3.3** 검증 명령을 (i) `leftover_jpg=0`, (ii) `sharp≥1`, (iii) `mask≤sharp` + `orphan_mask=0` 세 조건으로 완화 (이전 strict equal 강제 제거). | PAPER_DRAFT §3.2·§4.5e / experiments/RUN_PILOT.md·data/README.md |
| 2026-05-13 (sharp/mask 독립 collection 정합) | 사용자 수동 sharp reclassification 으로 인한 orphan mask 가능성 확인 (M ⊆ S 가정 깨짐). sharp/mask 를 *독립 collection* 으로 재정의하여 4 위치 wording 정합. **§3.2 (d)** "Sharp / mask 의 독립 collection 관계" 절 추가 — 두 비대칭 (skip_empty + manual reclassification) 모두 정상 명시 + mask on condition 을 sharp ∩ mask intersection 으로 한정. **§4.5e** ablation evidence 를 intersection I = S ∩ M 으로 정의 + orphan mask (M \ S) 자동 제외 + |I|/|S|, |M\S|/|M| 두 비율 결과표 부수 column 보고. **data/README.md §2** "Subset 관계" → "독립 collection — 부분집합/카운트 강제 없음" 으로 완전 재작성. **data/README.md §5** subset wording → pair 매칭 wording 으로 정정. **RUN_PILOT.md §3.3** 검증 명령에서 mask count + orphan_mask 비교 제거 — `leftover_jpg=0` + `sharp≥1` 두 조건만 검증 (mask 는 advisory). | PAPER_DRAFT §3.2·§4.5e / experiments/RUN_PILOT.md·data/README.md |

---

## Abstract (Korean)

산업현장 자율 로봇 배치는 LiDAR · multi-cam rig 의 설치 비용 제약으로 인해 *camera-only · body-worn* 형태의 3D 재구성에 대한 수요가 증가하고 있다. 그러나 보디캠 입력의 산업현장 3D 재구성은 textureless · reflective · 오염 · dynamic instance · scale 변동 · low-light · 비균질 조명의 일곱 부정 요인 (cluster A/B/C) 이 동시에 작용하는 도메인 특수성을 가지며, ScanNet · Replica 등 일반 indoor 벤치마크의 SOTA ranking 이 그대로 유지된다는 보장이 없다. 본 논문은 산업현장 보디캠 영상을 입력으로 9 개 최신 atomic 방법론 (COLMAP, GLOMAP, DUSt3R, MASt3R, DROID-SLAM, DPV-SLAM, MASt3R-SLAM, 3DGS, 2DGS) 의 9 pipeline configurations (P1–P9) 를 동일 공정성 프로토콜 하에서 비교 평가하고, 그 결과를 BEV occupancy + IsaacSim + Spot/RRT* navigation 까지 연결한 6 stage end-to-end 파이프라인을 구현하였다. 본 연구는 사후 cherry-picking 을 차단하기 위해 H-Best (P9 = MASt3R-SLAM + 2DGS 가 최상위), H-Worst (P1 = COLMAP + 3DGS 가 최하위), H-Gap (Δ_industrial > Δ_library), H-Mechanism (cluster A/B/C 각각에서 deep-prior 의 hand-crafted SfM 대비 우위) 의 네 가설을 사전등록한다. Moving-block bootstrap + site-level Wilcoxon signed-rank 의 이중 통계 검정과 cluster A/B/C frame-level mask ablation 을 통해 사전등록 가설이 산업현장 도메인의 reconstruction 품질 · navigation 성공률 양 axis 에서 falsifiable framework 으로 검증될 것이 예측된다. 본 결과로부터 "deep-prior pose + planar-prior representation" 의 domain-method matching design principle (C3) 을 도출한다.

**Keywords:** 3D 재구성, 산업현장 로봇 자율주행, 보디캠 영상, SLAM, Gaussian Splatting, 비교 평가, 도메인-메서드 매칭

---

## Abstract (English)

Deploying autonomous robots in industrial sites increasingly demands *camera-only · body-worn* 3D reconstruction, due to the installation-cost constraints of LiDAR and multi-camera rigs. However, body-worn industrial 3D reconstruction exhibits a domain specificity in which seven adverse factors — textureless, reflective, contamination, dynamic instances, scale variation, low-light, and non-uniform illumination (clusters A/B/C) — act simultaneously, making it doubtful whether the SOTA rankings established on canonical indoor benchmarks such as ScanNet and Replica are preserved in this domain. This paper presents an end-to-end 6-stage pipeline that takes industrial body-worn camera video as input, compares 9 modern atomic methods (COLMAP, GLOMAP, DUSt3R, MASt3R, DROID-SLAM, DPV-SLAM, MASt3R-SLAM, 3DGS, 2DGS) organised into 9 pipeline configurations (P1–P9) under a unified fairness protocol, and connects the results to BEV occupancy + IsaacSim + Spot/RRT* navigation. To preclude post-hoc cherry-picking, we pre-register four hypotheses: H-Best (P9 = MASt3R-SLAM + 2DGS ranks first), H-Worst (P1 = COLMAP + 3DGS ranks last), H-Gap (Δ_industrial > Δ_library), and H-Mechanism (deep priors dominate hand-crafted SfM under each of clusters A/B/C). Through a dual statistical test combining moving-block bootstrap with site-level Wilcoxon signed-rank, and through cluster-wise frame-level mask ablation, we expect the pre-registered hypotheses to be evaluated as a falsifiable framework on both reconstruction-quality and navigation-success-rate axes in the industrial domain. From these results we derive a domain-method matching design principle — "deep-prior pose + planar-prior representation" — as a generalisable design guideline (C3) for camera-only industrial robot autonomy.

**Keywords:** 3D reconstruction, industrial robot autonomy, body-worn camera, SLAM, Gaussian Splatting, comparative evaluation, domain-method matching

---

## §1 Introduction

본 장은 산업현장 보디캠 영상을 입력으로 한 3D 재구성과 로봇 자율주행 연계 평가의 (i) 산업적 동기 (§1.1), (ii) 일반 indoor 벤치마크 의존이 만드는 문제 (§1.2), (iii) 본 논문이 채우는 single-sentence research gap (§1.3), (iv) 세 contribution C1·C2·C3 및 사후 cherry-picking 차단을 위한 4개 사전등록 가설 (§1.4), (v) 본문 roadmap (§1.5) 을 차례로 제시한다.

### 1.1 Background — Industrial Robot Autonomy Demand

스마트팩토리 · 위험구역 점검 · 시설관리 자동화를 위한 자율 로봇 수요는 최근 가속화되었다. 그러나 산업현장 자율주행은 일반 indoor/outdoor 자율주행과 두 가지에서 차별화된다. 첫째, *경로 환경의 비정형성* 이다 — 좁은 통로, 임의로 배치된 자재, 변동하는 작업자 동선이 사전 정적 지도를 무력화한다. 둘째, *센서 비용 · 설치 제약* 이다 — 고가 LiDAR + multi-cam rig 기반의 robust mapping 은 산업현장 다수 site 의 신속 배포가 불가능하다. 두 제약은 *camera-only* + *body-worn* 형태의 데이터 수집을 산업현장에 매력적으로 만든다. 보디캠은 작업자의 자연스러운 동선을 따라 영상을 수집하므로 사전 사이트 셋업 비용이 사실상 0 에 가깝다.

문제는 보디캠 입력의 3D 재구성 성능이 산업현장 도메인의 cluster A · B · C 특성 (§3.5; textureless · reflective · 오염 · dynamic · scale 변동 · low-light · 비균질 조명) 에 의해 어떻게 영향받는지가 *공정한 비교 프레임* 안에서 평가된 적이 없다는 것이다. 본 논문은 이 빈자리를 채우는 것을 목적으로 한다.

### 1.2 Problem & Motivation — Why General Benchmarks Are Insufficient

기존 indoor 3D 재구성 / SLAM 벤치마크 — ScanNet [11], Replica [12], COLMAP benchmark [1], KITTI · Tanks-and-Temples 등 — 은 모두 *정돈된* 도메인을 가정한다. ScanNet 의 indoor scan 은 잘 조명된 가정/사무실 공간이며, Replica 는 photogrammetric quality 의 GT 메시를 제공하는 controlled 환경이다. 두 벤치마크의 SOTA ranking 은 본 논문이 다루는 산업현장 (콘크리트 + 금속 + 작업자 + 비균질 조명) 의 ranking 을 보장하지 않는다.

특히 산업현장은 cluster A (visual ambiguity) · cluster B (scene non-staticity) · cluster C (photometric drift) 세 부정적 요인이 *동시에* 작용한다. 일반 벤치마크는 각 요인 중 일부만 부분적으로 포함하므로 (예: ScanNet 의 작업자 동선 없음, Replica 의 photometric drift 없음) atomic method 의 도메인-적합성을 격리 평가할 수 없다. 결과적으로 "general benchmark 상위 방법론이 산업현장에서도 상위" 라는 묵시적 가정 은 본 논문이 의문시하는 출발점이다.

### 1.3 Research Gap

본 논문이 채우는 single-sentence research gap 은 다음과 같다.

> 산업현장 보디캠 영상을 입력으로 9 개 최신 3D 재구성 atomic methods (SfM · learning matching · deep SLAM · representation 4 계열) 및 그 조합 9 pipeline configurations 를 일관된 공정성 프로토콜로 비교 평가하고, 그 결과를 로봇 자율주행 task 에 연결한 연구는 아직 존재하지 않는다.

이는 세 sub-gap 으로 분해된다. **(G1) Camera-only industrial recon 의 표준 평가 부재** — 기존 산업/건설현장 연구 [19] 는 LiDAR · ToF 의존이며, 보디캠 입력 평가는 시도 자체가 드물다. **(G2) 9-method 횡단 비교의 부재** — 개별 method paper [1]–[9] 는 각자의 home benchmark 에서 평가될 뿐 양 도메인 (industrial vs library control) 횡단 비교는 부재하다. **(G3) End-to-end navigation 평가의 부재** — reconstruction 품질이 BEV occupancy → IsaacSim → RRT* [18] navigation 성공률에 미치는 영향을 정량 평가한 연구는 부족하다.

### 1.4 Contributions and Pre-registered Claims

본 논문의 세 기여는 다음과 같다. **C1 (β·비교평가).** 9 atomic methods × 2 domain (industrial · library control) 의 횡단 비교. **C2 (γ·시스템).** capture → preprocess → camera mapping → representation → mesh → BEV → IsaacSim → navigation 의 6 stage end-to-end pipeline 구현. **C3 (δ·디자인 원칙).** "domain mechanism 진단 → 메커니즘에 견디는 prior 선택" reasoning loop 의 산업현장 instantiation — "deep-prior pose + planar-prior representation" design principle (§5.4).

사후 cherry-picking 또는 HARK (hypothesizing after results are known) 의여지를 차단하기 위해 본 논문은 다음 네 가설을 *측정 전* 에 사전등록한다.

- **H-Best.** P9 (M7 MASt3R-SLAM [7] + M9 2DGS [9]) 가 9 configurations 중 산업현장 도메인에서 reconstruction quality + BEV IoU + RRT* success 의 종합 ranking 최상위.
- **H-Worst.** P1 (M1 COLMAP [1] + M8 3DGS [8]) 가 동일 종합 ranking 최하위.
- **H-Gap.** Δ_industrial > Δ_library 의 95% block bootstrap CI [26] 가 0 을 포함하지 않음 (one-sided).
- **H-Mechanism.** Cluster A · B · C 각각의 §4.5 ablation 에서 deep-prior pose method 의 *representative* (M7 MASt3R-SLAM [7]; P9 의 pose stage) 가 hand-crafted SfM 의 *representative* (M1 COLMAP [1]; P1 의 pose stage) 대비 frame budget 의 mask fraction 증가에 더 robust. *비고:* §4.5 ablation 은 9 configurations × 7 sub-cluster 행렬이 frame budget 한계로 inviable 하여 P1 vs P9 의 2-cell 비교로 축소 수행되며, deep-prior 계열 전체 (M3·M4·M5·M6·M7) 의 우위 일반화는 §5.2 의 mechanism 해석으로 보강된다.

본 4 가설의 verdict (supported / partial / refuted / inconclusive) 는 §5.1 Tab. 4 에 정직하게 등록된다.

### 1.5 Paper Roadmap

§2 에서 9 atomic methods 의 계보학적 정리와 산업현장 연구 부재를 정리한다. §3 에서 6 stage pipeline 구조 · cluster A/B/C 메커니즘 분석 · 공정성 프로토콜을 정의한다. §4 에서 사전등록 가설을 falsification 한다. §5 에서 mechanism 해석과 design principle 을 도출하고, §6 에서 결론 및 future work 을 제시한다.

> *(§1 → §2 transition)* 다음 절에서는 본 비교에 포함된 9 atomic methods 의 계보학적 정리와 산업현장 도메인 연구 부재를 정리한다.

---

## §2 Related Work

본 장은 본 비교평가에 포함된 9 atomic methods [1]–[9] 를 4 계열 (§2.1 SfM · §2.2 learning matching · §2.3 deep SLAM · §2.4 3D representation) 로 구조화하고, §2.5 산업현장 / cluttered 도메인 연구의 부재, §2.6 navigation-from-reconstruction 연구의 부재를 정리한 뒤, §2.7 에서 본 논문이 채우는 4-way intersection 을 명시한다.

### 2.1 Structure-from-Motion

**COLMAP** [1] 은 SIFT [10] 기반 hand-crafted feature 의 incremental SfM 으로, multi-view geometry 의 *de facto* baseline 으로 두 가지 점에서 본 논문에 포함된다 — (i) feature-based hand-crafted pipeline 의 representative, (ii) 후속 deep matching · deep SLAM 의 비교 anchor. **GLOMAP** [2] 은 COLMAP 의 incremental BA 를 *global* rotation/translation averaging 으로 대체한 후속 SfM 이며, scale-up 환경에서 incremental 의 drift 누적 문제를 일부 완화한다. 그러나 두 방법 모두 SIFT [10] keypoint 의 repeatability 에 의존하므로 textureless · reflective region (§3.5 cluster A.1, A.2) 에서 매칭 실패가 발생한다 — Romanoni et al. [24] 의 TAPA-MVS 가 textureless 환경의 dense matching 부재를 정량적으로 보고한 것이 이 한계의 *방증* 이다. 본 한계는 산업현장 (콘크리트 벽 · 금속 외관) 에 fundamental 으로 작용하며, §4.5b–c 의 ablation 으로 직접 검증된다.

### 2.2 Learning-based Matching

**DUSt3R** [3] 은 pairwise image 쌍에서 dense 3D point 를 *end-to-end regression* 하는 transformer 기반 모델로, hand-crafted feature 의 keypoint repeatability 의존을 우회한다. **MASt3R** [4] 은 DUSt3R 의 후속으로 multi-view matching loss 와 scale awareness 를 추가하여 sparse-view 환경에서 metric scale 의 정확도를 개선한다. 두 모델 모두 학습 분포의 inductive bias 로 인해 industrial / OOD 영상의 *표준화된 평가* 가 부재하며, 본 논문은 이 부재를 1 차로 채우는 비교의 대상으로 두 모델을 stage 3 pose method 로 포함한다.

### 2.3 Deep SLAM

Deep SLAM 은 RGB-only · low-cost sensor 시나리오에서 traditional SLAM 의 robustness 한계를 우회하는 학습 기반 SLAM family 이다. **DROID-SLAM** [5] 은 dense optical flow + recurrent BA 의 학습 기반 결합으로 monocular · stereo · RGB-D 입력 모두에 강건한 pose tracking 을 보여준다. **DPV-SLAM** [6] 은 DROID 의 dense feature volume 을 patch-graph 로 sparse 화하여 memory footprint 를 줄인 후속 모델이며, on-device 또는 long-sequence 시나리오에 적합하다. **MASt3R-SLAM** [7] 은 MASt3R [4] 의 dense matching prior 를 SLAM frontend 에 직접 결합한 가장 최근 모델로, 본 논문 sub-thesis 의 핵심 — *deep-prior pose method 가 산업현장 cluster A/B/C 모두에서 우위* — 의 representative 이다. 세 deep SLAM 의 일반 도메인 robustness 는 잘 검증되었으나, 산업현장에서의 *상대 격차* 는 미보고이며 본 논문이 채운다 (§4.3 Table 2). 또한 cluster B.1 (dynamic instance) 에 대해서는 DynaSLAM [23] 류의 dynamic-aware SLAM 이 explicit mask 로 우회하는 반면, deep SLAM 은 학습 분포 의 inductive bias 로 implicit 으로 robust 함을 보여준다 (§5.2 dialogue).

### 2.4 3D Representations: 3DGS vs 2DGS

**3DGS** [8] 은 anisotropic 3D Gaussian primitive 를 explicit scene representation 으로 사용하여 photorealistic novel-view synthesis 와 빠른 학습/렌더링을 동시에 달성한 representation paradigm 이다. **2DGS** [9] 는 3DGS 의 primitive 를 surface-aligned 2D oriented disk 로 대체하여 surface normal 이 well-defined 되도록 한 변형이며, native mesh extraction (TSDF fusion) 의 quality 가 3DGS 대비 향상된다. 본 논문은 산업현장의 dominant geometry 가 *평면적* (벽 · 바닥 · 기계 외관) 이라는 도메인 prior 가 2DGS 의 surface alignment 와 정합한다는 가설 — H-Best 의 표 두 번째 축 — 을 사전등록하며 (§1.4, §3.4), §5.3 에서 이 가설의 메커니즘적 해석을 전개한다.

### 2.5 Industrial / Cluttered Domain Reconstruction

산업현장 · 건설현장의 point cloud / mesh recon 연구는 대부분 *LiDAR · ToF · 정밀 photogrammetry rig* 에 의존해 왔다. Bosché [19] 는 BIM as-built 검증을 위한 LiDAR 기반 mesh 비교를 제시했으며, Xue et al. [20] 의 image-based 건설현장 progress monitoring review 는 카메라 입력의 가능성을 제시하나 평가의 단일 method 한정과 task-specific framing 으로 atomic method 횡단 비교는 부재하다. 가장 최근의 Sun et al. [21] 은 건설현장 surveillance camera 기반 near-real-time recon 을 시도했으나 single method (NeRF-variant) 적용에 그치며 9-method 횡단 비교는 부재하다. 본 논문은 (i) *body-worn camera* (rather than fixed surveillance), (ii) *9 atomic method 횡단 비교*, (iii) *navigation 평가까지 연계* 의 세 점에서 [19], [20], [21] 의 빈 자리를 정확히 채운다.

### 2.6 Robot Navigation from Reconstructed Maps

Reconstructed mesh · point cloud 를 BEV occupancy grid 로 변환하여 sampling-based planner (RRT* [18] · PRM) 또는 cost-map planner 에 입력하는 pipeline 은 mobile robotics 에서 widely deployed 이나, 본 논문이 주목하는 *"reconstruction quality 가 navigation success rate 에 미치는 정량적 영향"* 자체는 standard benchmark 가 부재하다. IsaacSim 의 GPU-parallel simulation API 는 mesh → USD scene → physics-enabled navigation 의 batch 평가를 가능하게 하나, 이 capability 를 9 atomic methods 의 횡단 비교에 적용한 사례는 본 논문이 첫 보고이다.

### 2.7 Synthesis: What This Paper Adds

§2.1–§2.6 의 정리를 단일 statement 로 합치면, 본 논문이 채우는 빈자리는 다음 4-way intersection 이다 — **(industrial body-worn camera domain)** × **(camera-only input)** × **(9-method 횡단 비교)** × **(end-to-end navigation 평가)**. 위 4 축 어느 하나만 missing 인 prior work 들은 존재하나 (LiDAR 산업현장, 일반 도메인 9-method 비교, mesh-from-Gaussian extraction, sim navigation), 네 축이 *동시에* 만나는 연구는 본 논문이 첫 사례이다. 본 횡단성이 §3 의 시스템 contribution (C2) 과 §5.4 의 design principle (C3) 의 외부 타당성 근거가 된다.

> *(§2 → §3 transition)* 다음 장에서는 본 비교의 전제가 되는 파이프라인 구조 · 메커니즘 분석 · 공정성 프로토콜을 정의한다.

---

## §3 Pipeline Design

본 장은 산업현장 보디캠 영상을 입력으로 받아 9 pipeline configurations (P1–P9; Table 1b)을 일관된 공정성 프로토콜 하에서 비교하고, 그 결과를 로봇 자율주행(BEV occupancy + IsaacSim + RRT*)까지 연결하는 end-to-end 파이프라인의 구조를 정의한다. §3.1에서 전체 6 stage 구조를 개관하고, §3.2에서 9 configurations에 공통 적용되는 전처리 모듈을 명세한다. §3.3에서 9 atomic methods의 계열 분류와 9 pipeline configurations 정의(Table 1b)를 제시하고, §3.4에서 representation stage의 hyperparameter 통제 원칙을 기술한다. §3.5에서 산업현장 도메인의 메커니즘 클러스터(A/B/C)를 분석하여 §4.5 ablation의 사전 가설을 제공하고, §3.6에서 양 도메인 비교의 공정성 프로토콜을 정의한다. §3.7에서 reconstruction → mesh → BEV → IsaacSim 변환 단계를 명세한다.

### 3.1 Pipeline Overview

본 논문이 제안하는 파이프라인은 보디캠 raw video를 입력으로 받아 로봇 자율주행 시나리오의 RRT* 경로계획 결과를 최종 산출하는 6 stage 직렬 구조를 가진다 [Fig. 1: Pipeline overview — 6 stage block diagram (video → preprocess → pose+sparse → dense representation → mesh → BEV occupancy → navigation harness)]. Stage 1 (capture) 은 보디캠 30 fps RGB 영상 수집, Stage 2 (preprocess; §3.2) 는 FPS 정규화·sharpness 기반 blur 제거·dynamic 영역 마스크 생성, Stage 3 (camera mapping; §3.3) 은 7개 pose-capable atomic methods (M1 COLMAP [1], M2 GLOMAP [2], M3 DUSt3R [3], M4 MASt3R [4], M5 DROID-SLAM [5], M6 DPV-SLAM [6], M7 MASt3R-SLAM [7]) 중 하나를 통해 카메라 포즈와 sparse 3D points를 추정한다. Stage 4 (representation; §3.4) 는 2개 atomic representations (M8 3DGS [8], M9 2DGS [9]) 중 하나로 dense 3D 표현을 학습한다. Stage 5 (mesh + BEV; §3.7) 는 학습된 Gaussian primitives로부터 mesh를 추출하고 top-down 정사투영(orthographic projection)으로 2D occupancy grid를 생성한다. Stage 6 (navigation harness; §3.7, §4.6) 은 IsaacSim 환경에 mesh를 임포트하여 Spot 사족보행 로봇과 RRT* [18] 경로계획기를 결합한 시뮬레이션을 수행한다.

본 논문이 가변화시키는 stage는 Stage 3 (pose)과 Stage 4 (representation) 두 단계만이며, 나머지 4 stage는 모든 configuration에 대해 동일하게 고정한다. 즉, 본 비교평가는 "pose × representation 조합이 reconstruction 품질과 navigation 성공률에 미치는 영향"의 분리 측정에 초점이 맞추어져 있다.

### 3.2 Preprocessing Module *(C2-sub-a; α structural contribution)*

전처리 모듈은 9 configurations 에 동일하게 적용되어 공정성을 보장하는 모든 입력 측의 전처리를 묶은 단위이며, 본 논문의 시스템 기여 (C2-sub-a) 의 α-contribution 에 해당한다. 본 모듈은 보디캠 raw video 를 입력으로 받아 (i) sharp RGB frame 집합 + (ii) frame 와 1:1 매칭되는 binary exclusion mask 집합 (값 255 = 학습 보존 / 0 = 학습 제외) 을 출력하는 *human-in-the-loop video-to-image preprocessing pipeline* 로 통합 구현되며, 네 sub-stage 와 한 검증 단계로 구성된다.

**(a) Frame extraction with aspect-locked crop.** FFmpeg 기반 사용자 지정 FPS 추출 (본 논문 default 5 fps). 첫 frame 에서 ROI 를 드래그 지정하여 `crop=W:H:X:Y` 필터를 적용하되, source 비율을 유지 (aspect-locked) 하여 SfM/SLAM 가정의 camera intrinsics 일관성을 보존한다. 본 단계는 P9 의 M7 MASt3R-SLAM [7] 이 frame-to-frame intrinsics 불변을 전제하므로, fairness protocol §3.6 F1 (GPU 통제) 과 별개로 입력 단계에서 reconstruction 의 기하 안정성을 확보하는 핵심 통제이다.

**(b) Sharpness-based 4-bucket classification.** Frame 별 Laplacian 분산 (blur score) [15] 을 계산하여 사용자 조정 threshold 로 `sharp/` ↔ `blur/` 두 bucket 으로 자동 이분한다. 본 자동 분류에 더해 (i) 재구성에서 명시적으로 제외할 frame 을 `drop/` bucket 으로 수동 격리, (ii) §3.2 (c) dedup 결과의 redundant frame 을 `dup/` bucket 으로 격리 — 총 4-bucket {sharp, blur, drop, dup} 분류 시스템을 형성한다. 모든 분류는 *가역적 (reversible)* 이며 video 재추출/재동기화 후에도 보존된다.

**(c) dHash-based duplicate detection.** Sub-stage (a)–(b) 통과 frame 중 보디캠 작업자의 정지·저속 구간에서 visually redundant 한 frame 군집이 다수 존재한다 (예: 동일 장비를 5–10 sec 응시). 8×8 difference-hash (dHash) perceptual hashing 으로 frame-level 64-bit hash 를 산출하고, 가변 Hamming distance threshold (range 0–20, default 5) 로 redundancy 를 판정하여 `dup/` bucket 으로 이동한다. 본 단계는 단순 FPS downsample 만으로는 보존되는 *static-pose 군집* 을 제거하여 두 도메인 (industrial vs library control) 간 effective view diversity 를 정규화한다.

**(d) SAM 2.1 / SAM 3 unified masking backend.** Sub-stage (a)–(c) 통과 sharp frame 에 대해 binary exclusion mask 를 자동 생성한다. 본 모듈의 단일 mask backend (`SAMEngine` facade) 는 SAM 2.1 [13] (Tiny / Small / Base+ / Large; device 별 자동 선택) 와 SAM 3 (CUDA 한정) 의 두 model family 를 추상화하며, 세 가지 prompting mode 를 통합 지원: (i) **point prompt** — 단일 frame 객체 클릭 → instance mask, (ii) **single-click video propagation** — sharp/ 시퀀스 전체에 시간적으로 일관된 mask 자동 전파, (iii) **text-prompt 일괄 mask** — SAM 2.1 backend 는 Grounded-SAM 2 (Grounding DINO 검출 → SAM segment), SAM 3 backend 는 native Promptable Concept Segmentation. 모든 도구는 산업현장 fine-tuning 없이 default weight 사용. **Sharp / mask 의 독립 collection 관계:** sharp 집합 S 와 mask 집합 M 은 둘 다 *독립 collection* 으로 다루며 부분집합 관계 (M ⊆ S 또는 S ⊆ M) 를 가정하지 않는다 — 두 collection 사이에 두 종류의 비대칭이 발생할 수 있다: (i) `skip_empty` 정책 — dynamic instance 검출이 0건인 frame 에 대해 mask 파일을 출력하지 않으므로 |M| < |S| 가 일반적 (특히 library control 도메인 또는 industrial site 의 작업자 부재 구간), (ii) `sharp manual reclassification` — §3.2 (e) 의 human-in-the-loop dashboard 또는 directory-level manual removal 로 sharp 의 일부 frame 이 사후 제거된 경우, 그에 대응하는 mask 가 *orphan* 으로 남아 M ⊄ S 가 가능. 본 두 경우 모두 본 논문에서 정상 상태로 간주된다. 본 모듈은 `mask on (sharp ∩ mask intersection 의 mask 영역을 학습에서 제외; intersection 밖 frame 은 그대로 학습 포함) / mask off (모든 sharp frame 을 그대로 학습 포함)` 두 condition 을 §4.5e cluster B.1 ablation 의 직접 입력으로 제공한다. P1 / P9 의 primary 학습 단계에서는 mask 미참조 (sharp 만 사용).

**(e) Human-in-the-loop verification.** Sub-stage (a)–(d) 의 산출물은 React 19 + MUI 9 기반 단일 페이지 dashboard 에서 4-step stepper ([01] INPUT → [02] PIPELINE → [03] FRAMES → [04] MASKING) 로 검증된다. 빨강 overlay grid 로 frame 별 mask 시각 검증을 수행하고, 키보드 단축키 (`S`/`B`/`D` = SHARP/BLUR/DROP, `←`/`→` = navigation) 로 대량 frame 의 빠른 재분류가 가능하다. 모든 manual reclassification 은 `POST /reclassify-bulk` 의 단일 API call 로 일괄 처리되며 가역적이다. 본 단계는 fairness protocol §3.6 F5 의 공개 commitment 에 따라 최종 분류 결과 (sharp / blur / drop / dup bucket assignment) 가 site 별 manifest 로 publication 시 배포된다.

[Alg. 1: Preprocessing pseudocode — input bodycam video → (a) FFmpeg FPS-based frame extraction + aspect-locked crop → (b) Laplacian variance 4-bucket {sharp, blur, drop, dup} 자동 + 수동 분류 → (c) 8×8 dHash + Hamming threshold dedup → (d) SAM 2.1 / SAM 3 unified backend (point ∨ video-propagation ∨ text-prompt) binary exclusion mask → (e) human-in-the-loop verification 가역적 reclassification → output {sharp frame set + 1:1 매칭 exclusion mask set}].

본 모듈의 표준 output layout (`<scene>/{sharp,blur,drop,dup,masks,mask_preview}/`) 에서 ARS pipeline 은 `sharp/` (학습 입력) 와 `masks/` (1:1 매칭 exclusion mask) 두 폴더만 downstream 으로 진입시킨다 (3DGS / 2DGS / COLMAP-SfM 모두 직결). 9 configurations 의 Stage 3 입력으로 공통 진입하므로 configuration 간 차이는 Stage 3·4 의 atomic method 조합에서만 발생한다. 본 모듈의 구현체 (4 sub-stage 의 threshold · hyperparameter · 최종 bucket manifest 포함) 는 §3.6 F5 의 공개 commitment 에 포함된다.

### 3.3 Camera Mapping Stage

> **Terminology disambiguation.** 본 논문은 "9 atomic methods" (각 method가 stage 역할 고정 단위)와 "9 pipeline configurations" (pose × representation 조합 단위)를 구분한다. C1의 "9-method comparison evaluation"은 *9 atomic methods*를 의미하며, end-to-end 비교는 9 pipeline configurations (Table 1b) 단위로 수행된다. H-Best/H-Worst는 configuration 수준의 사전등록 가설이다.

[Tab. 1: 9 atomic methods × stage 역할 × 계열 — M1 COLMAP [1] / M2 GLOMAP [2] / M3 DUSt3R [3] / M4 MASt3R [4] / M5 DROID-SLAM [5] / M6 DPV-SLAM [6] / M7 MASt3R-SLAM [7] / M8 3DGS [8] / M9 2DGS [9], 4 계열 (SfM hand-crafted / learning matching / deep SLAM / representation)].

[Tab. 1b: 9 pipeline configurations P1–P9 — (P1) COLMAP+3DGS **H-Worst**, (P2) COLMAP+2DGS, (P3) GLOMAP+3DGS, (P4) DUSt3R+3DGS, (P5) MASt3R+2DGS, (P6) DROID-SLAM+3DGS, (P7) DPV-SLAM+2DGS, (P8) MASt3R-SLAM+3DGS, (P9) MASt3R-SLAM+2DGS **H-Best**].

Tab. 1b의 9 configurations은 full 7×2 grid (14 configurations) 중 다음 세 가지 설계 제약을 만족하는 budget-aware subset이다. 첫째, 7개 atomic pose methods 각각이 ≥1 configuration에 등장하여 pose 계열 coverage를 보존한다. 둘째, COLMAP과 MASt3R-SLAM 두 pose method는 representation을 toggle한 두 configuration쌍(P1↔P2, P8↔P9)을 가져 representation 효과(3DGS↔2DGS)의 사후 격리(§5.3)가 가능하다. 셋째, §4.6 navigation evaluation의 default budget이 9 × 6 × 20 = 1,080 runs로 약 36시간 wall-clock에 해당하며, full grid 시 1,680 runs로 비현실적이라는 실용 제약을 반영한다.

Pose-only atomic methods (M1, M2, M5, M6) 의 산출물은 카메라 외부 파라미터와 sparse 3D points이며, 이를 Stage 4 representation 학습의 초기 seed로 직접 투입한다. DUSt3R [3] · MASt3R [4] · MASt3R-SLAM [7] 은 native dense 출력(pairwise pointmap 또는 SLAM dense reconstruction)을 가지며, 본 논문에서는 dense 출력을 Stage 4의 추가 seed로 함께 사용하되 pose 정보는 동일한 camera 외부 파라미터 형태로 정규화하여 입력한다(§3.4 hyperparameter 통제).

### 3.4 3D Representation Stage

Stage 4의 두 atomic representations (M8 3DGS [8], M9 2DGS [9]) 은 모두 동일 hyperparameter budget으로 학습된다. Configuration별 차이는 (i) pose 입력의 출처와 (ii) representation 클래스 두 가지에서만 발생하며, 그 외의 training schedule (max iteration, learning rate schedule, densification interval, opacity reset interval) 은 각 representation 저자 권장값 [8], [9] 을 그대로 사용한다. 두 representation은 native code base의 default hyperparameter가 서로 다르므로 동일 절대값으로 강제 통일하지 않고 *권장 default를 그대로* 사용함을 명시한다 — 이는 §3.6의 "hyperparameter default 사용" 공정성 원칙의 직접 적용이다.

### 3.5 Industrial Domain Characteristics + Mechanism Clusters A/B/C

산업현장은 일반 indoor 벤치마크 [11], [12] 와 달리 세 가지 mechanism cluster가 동시에 작용한다. 본 절에서는 각 cluster의 sub-cluster와 frame-level operational mask 정의를 제시하며, §4.5 ablation에서 동일 정의를 사용하여 causality를 분리 검증한다.

**Cluster A — Visual Ambiguity.** (A.1) Textureless: 벽·바닥·콘크리트의 gradient sparsity → SIFT [10] 류 hand-crafted feature의 keypoint repeatability 붕괴 (TAPA-MVS [24] 가 보고한 textureless 영역의 dense matching 부재 문제). (A.2) Reflective: 금속 외관의 view-dependent appearance → multi-view photometric consistency 위반 (Ref-NeRF [22] 가 강조한 specular highlight 모델링 필요성). (A.3) 오염: 먼지·페인트 박리에 의한 partial occlusion + texture anomaly → keypoint matching의 outlier 주입 (MVTec AD [25] anomaly segmentation 관행을 mask 정의에 차용).

**Cluster B — Scene Non-staticity.** (B.1) Dynamic objects: 작업자·이동 자재 → 정적 scene 가정을 위반하여 pose estimation의 outlier 주입 (DynaSLAM [23] 류 dynamic-aware SLAM이 우회 대상으로 삼는 신호). (B.2) Scale 변동: 보디캠 근접 촬영(0.5m)과 원거리 통로(20m)가 한 영상에 혼재 → depth ambiguity 및 frame 간 scale 일관성 위반.

**Cluster C — Photometric Drift.** (C.1) Low-light: 조명 음영 영역에서 SNR 저하 → photometric loss 의 dominant term 왜곡. (C.2) 비균질 조명: 직사 스포트라이트 + 형광등 mixed → color constancy 위반.

[Tab. 3.5: Sub-cluster operational mask 정의 — A.1 Sobel gradient magnitude < τ_tex / A.2 HSV V-channel saturation peak / A.3 color variance + edge density anomaly / B.1 SAM2/YOLO instance mask / B.2 depth prior median 비율 > τ_scale / C.1 mean luminance < τ_lum / C.2 luminance variance > τ_var (frame 내부)].

[Fig. 2: Sample frames per sub-cluster — 7 sub-cluster (A.1/A.2/A.3/B.1/B.2/C.1/C.2) montage on industrial sites].

Library control 도메인은 Cluster A·B·C 세 cluster 모두에서 산업현장 대비 강도가 낮다(static + good lighting + textured shelves; §4.1 참조). 따라서 H-Gap (§1.4) 의 Δ_industrial > Δ_library 가설은 동일한 9 configurations이 두 도메인에 적용될 때 산업현장의 cluster A/B/C 작용에 의해 deep-prior 우위가 증폭된다는 메커니즘적 예측에 직접 대응한다.

### 3.6 Fairness Protocol

9 configurations × 2 domains의 비교가 reconstruction 품질의 *방법 효과*만 반영하도록 다음 제약을 적용한다.

**(F1) GPU 환경 통제.** 모든 configuration은 동일 GPU 클래스(RTX 4090)에서 실행한다. 본 실험은 2-host × 2-GPU = 총 4 GPU 환경에서 수행하며, 구체적 분배는 P1 (M1 COLMAP / M8 3DGS) · P9 (M7 MASt3R-SLAM / M9 2DGS) 의 pose · representation stage를 각각 host-local GPU 0 · 1에 고정한다.

**(F2) Compute budget 통제.** 모든 representation은 동일 max iteration (30,000) 으로 학습하며, default hyperparameter [8], [9] 외 추가 튜닝은 적용하지 않는다.

**(F3) Preprocessing 통제.** §3.2의 FPS · sharpness threshold · mask 생성 모듈은 9 configurations × 2 domains에 동일하게 적용된다.

**(F4) 영상 길이 정규화.** Industrial 원본(약 5 min/site)과 Library 원본(약 1–2 min/site)의 비대칭을 제거하기 위해 두 도메인 모두 동일 frame budget N_frames = 1,500 *(§3.2 의 sub-stage (a)–(c) 통과 후 effective frame 수)* 로 trim/sub-sample 한다. 즉 budget 정의는 raw frame 수가 아니라 FPS-downsample + blur removal + similarity dedup 의 3-stage 통과 후의 sharp frame 수이며, 이 정의가 두 도메인의 effective information density 를 균질화한다. Library 원본이 짧아 dedup 후 1,500 frame 에 미달할 경우 zero-pad 대신 *동일 frame budget 내 dense temporal resampling* 으로 채우며, industrial 원본이 길 경우 등간격 sub-sample 을 사용한다. 본 정규화는 Δ 비교에서 영상 길이가 third variable 로 작용하는 것을 차단한다.

**(F5) 공개 commitment.** 본 논문의 코드·preprocessing mask·configuration별 hyperparameter는 publication 시점에 공개된다.

### 3.7 BEV + IsaacSim Integration *(C2-sub-c)*

Reconstruction stage의 산출물은 Gaussian primitives이며, navigation 평가를 위해서는 (i) mesh, (ii) BEV occupancy, (iii) IsaacSim scene 의 세 추가 변환 단계가 필요하다. 본 절의 sub-stage 번호 (5a / 5b / 6a / 6b) 는 §3.1 의 전체 6 stage 구조 (Stage 5 = mesh + BEV, Stage 6 = navigation harness) 와 정렬된다.

**Sub-stage 5a — Gaussian → Mesh extraction.** 3DGS [8] 와 2DGS [9] 는 native mesh를 출력하지 않으므로 별도 extractor를 적용한다. 2DGS configurations (P2, P5, P7, P9) 는 surface-aligned 2D disks의 normal field가 native하게 mesh-friendly이므로 Huang et al. [9] 의 TSDF fusion protocol을 그대로 사용하여 mesh를 직접 추출한다. 3DGS configurations (P1, P3, P4, P6, P8) 는 외부 extractor SuGaR [17] 의 default config를 모든 3DGS configuration에 일관 적용하여 extractor-induced bias를 제거한다. Pose-only atomic methods (M1, M2, M5, M6) 의 sparse point cloud 에 대한 Poisson surface reconstruction [16] (default depth = 9) 은 본 비교 평가의 *주 실험 대상이 아니며*, future work (§6.2 F2 multi-modal sensor fusion baseline) 의 reference slot 으로만 기록한다. 본 §4 의 모든 9 configurations 는 pose-only sparse points 를 Stage 4 의 3DGS/2DGS 초기 seed 로 투입한 뒤 Stage 4 dense representation 의 학습 결과로 mesh 를 추출한다 (§3.4).

**Sub-stage 5b — BEV occupancy grid construction.** Mesh를 z축 정사투영하여 2D grid (cell size = 0.05 m) 로 voxelize한다. 로봇 통행 가능 영역의 정의는 z ∈ [0.1 m, 2.0 m] 의 height threshold를 적용하며, 이는 Spot 사족보행 로봇의 body clearance에 대응한다. [Alg. 2: BEV occupancy grid construction pseudocode]. [Alg. 3: Gaussian → mesh extraction (2DGS native TSDF / 3DGS SuGaR [17]) pseudocode].

**Sub-stage 6a — IsaacSim import.** Mesh는 USD format (USDA scene + USDC binary) 으로 export되어 IsaacSim scene에 import된다. Spot 로봇은 default URDF + IsaacSim 공식 quadruped controller 로 배치되며, 물리 시뮬레이션은 60 Hz 고정이다.

**Sub-stage 6b — Navigation harness.** RRT* [18] (sampling radius = scene diagonal / 20, max iter = 5,000) 를 BEV occupancy grid 위에서 실행하여 start–goal pair마다 경로를 산출한다. Start/goal pair는 §4.6의 sampling protocol에 따라 scene당 K개 (default K = 20) 가 사전 결정되어 9 configurations에 동일하게 적용된다.

본 4-stage 변환은 reconstruction 품질이 navigation 성공률에 미치는 영향을 측정 가능한 단일 metric chain (BEV IoU → RRT* success rate) 으로 변환한다. 이 chain의 정량 평가는 §4.6 에서 보고된다.

> *(§3 → §4 transition)* 다음 장에서는 §3에서 정의된 공정성 프로토콜 하에서 9 pipeline configurations × 2 domain 비교 평가와 메커니즘 ablation을 수행한 결과를 보고한다.

---

## §4 Experiments

본 장은 §3에서 정의된 공정성 프로토콜 하에서 9 pipeline configurations (P1–P9) × 2 domains (Industrial, Library) 의 비교 평가와 mechanism ablation, 그리고 IsaacSim + Spot + RRT* navigation 평가의 결과를 보고한다. §1.4의 사전등록 가설 H-Best (P9), H-Worst (P1), H-Gap (Δ_industrial > Δ_library), H-Mechanism (cluster A/B/C 각각에서 deep-prior 우위) 의 falsification을 명시적으로 수행하며, 모든 통계 검정은 §4.4의 block-aware bootstrap [26] 을 primary, Wilcoxon signed-rank를 secondary로 사용한다. 본 draft 시점의 정량 수치는 pilot 실행 결과 산출 전이므로 `(TBD)` 로 표기하며, 표·그림 자리는 placeholder로 둔다.

### 4.1 Datasets

본 논문의 비교 평가는 두 도메인 각 3개 site, 총 6개 site의 보디캠 영상에 기반한다. **Industrial domain (3 site).** I-1 생산라인(금속 외관 + 작업자 동선; cluster A.2 · A.3 · B.1 dominant), I-2 외부 점검 통로(콘크리트 + 저조도; A.1 · A.3 · C.1 · C.2 dominant), I-3 기계실(반사재질 + 좁은 공간; A.2 · A.3 · B.2 dominant)로 구성된다. 각 site는 동일 GoPro 보디캠으로 5 min × 30 fps RGB로 수집되었다. **Library control domain (3 site).** L-1, L-2, L-3 는 정돈된 indoor library (static + good lighting + textured shelves) 로, 산업현장 cluster A/B/C 강도가 모두 낮다. Library 원본 영상은 1–2 min로 industrial 대비 짧으나 §3.6 F4 에 따라 동일 frame budget (N_frames = 1,500) 으로 정규화된다. 모든 site의 raw 영상·extracted frames·intrinsics 캘리브레이션·SAM2/YOLO mask는 §3.6 F5 의 공개 commitment에 따라 publication 시 함께 배포된다. [Tab. 4.1: Site characteristics table — site ID × dominant sub-cluster (A.1/A.2/A.3/B.1/B.2/C.1/C.2) × frame count × video length].

### 4.2 Metrics

본 평가는 세 metric family를 사용한다.

**(M1) Reconstruction quality.** PSNR · SSIM · LPIPS 는 held-out novel view 8 frame (전체 frame budget의 ~0.5%) 에 대해 측정되며, 상위 값이 우수(higher-is-better). PSNR/SSIM은 standard formula, LPIPS는 AlexNet backbone default를 사용한다. Chamfer Distance (CD) 는 양방향 거리로 측정하며 (lower-is-better) reference mesh 의 정의는 도메인별로 다르다 — **Library control:** library 3 site 의 P9 (MASt3R-SLAM + 2DGS) configuration 으로 산출된 mesh 가 본 도메인에서 density · surface quality 가 가장 높으므로 *low-bar reference* (사전 best-effort scan 대용) 로 commit 하며, P1–P8 의 mesh 는 본 reference 와의 CD 로 평가된다. **Industrial domain:** GT mesh 가 부재하므로 single reference 사용이 불가능 — 9 configurations 의 mesh 들 간 pair-wise CD matrix 를 산출하여 *configuration 간 mesh agreement* 의 site-internal 일관성 지표로 보조 보고한다 (즉 industrial CD 는 ranking metric 이 아닌 inter-method consistency diagnostic 으로 사용).

**(M2) Robot navigation suitability.** BEV occupancy IoU 는 §3.7 Stage 1의 BEV grid와 *manual annotation grid* (저자 작성, inter-annotator agreement는 §5.6에 보고) 간 IoU 로 측정 (higher-is-better). RRT* [18] success rate는 site당 K = 20 start–goal pair (Option B tiered design, §4.6 참조) 에 대한 경로 발견 비율로 측정 (higher-is-better). 부수 metric으로 average path length (lower-is-better; 우회 경로 penalty)와 collision count per run (lower-is-better)을 함께 보고한다.

**(M3) Efficiency.** GPU memory peak (VRAM, GB), wall-clock time per scene (sec) 을 representation 학습 시점에서 측정한다. 본 metric은 본문 Table 2에서는 요약(평균)만, 상세 분포는 Appendix B에 별도 보고한다.

각 metric의 higher/lower-is-better 방향은 Tab. 2 헤더에 명시된다.

### 4.3 Main Result — 9 Pipeline Configurations × 2 Domain Comparison

[Tab. 2: 9 configurations (P1–P9; §3.3 Table 1b) × 2 domains (Industrial, Library) × {PSNR, SSIM, LPIPS, Chamfer, BEV IoU, Nav success rate, mem (GB), time (sec)} — 각 cell에 "expected (사전등록) → observed (TBD)" 병기 형식].

[Fig. 3: Bar chart per metric per domain (with 95% block-bootstrap error bars), bar group이 configuration ID (P1–P9)].

**사전등록 vs 관측 (TBD).** §1.4 의 H-Best = P9 (M7 MASt3R-SLAM [7] + M9 2DGS [9]), H-Worst = P1 (M1 COLMAP [1] + M8 3DGS [8]) 는 본 Table 2의 industrial column에서 각각 최상위 · 최하위 ranking 을 예측한다. 만약 관측 ranking이 사전등록 ranking과 일치하면 두 hypothesis는 *supported*, 일부 metric에서만 일치하면 *partial*, 반대 ranking이 나오면 *refuted*, n=3 사이트 sample 부족으로 통계적 유의가 도달하지 못하면 *inconclusive* 로 §5.1 Tab. 4 에 verdict 등록된다.

**Configuration pair 비교의 관전 포인트.** (i) P1 vs P2 (COLMAP × {3DGS, 2DGS}) 와 P8 vs P9 (MASt3R-SLAM × {3DGS, 2DGS}) 는 representation 효과의 격리 (§5.3 "Why 2DGS > 3DGS"); (ii) P1 vs P9 의 cross-axis 비교는 H-Gap 계산의 reference pair; (iii) P6/P7 (DROID-SLAM, DPV-SLAM 계열) 은 deep SLAM 내부에서 MASt3R-SLAM 의 priors 차별이 어디서 발생하는지를 진단한다.

본문 Table 2는 reconstruction quality + navigation suitability 중심으로 구성하며, mem · time 의 distribution detail은 차원 축소를 위해 Appendix B로 이관한다.

### 4.4 H-Gap Statistical Test

H-Gap 가설 — Δ_industrial > Δ_library — 은 두 도메인 각각에서 (Best score) − (Worst score) 의 차이를 계산한 뒤 두 Δ 의 차이의 신뢰구간을 산출하여 검정된다. Δ_industrial / Δ_library 는 Table 2의 P9 (H-Best) vs P1 (H-Worst) 두 configuration 간 metric 차이로 정의된다.

**Primary — Moving-block paired bootstrap (Künsch [26]).** 동영상 frame 간 temporal correlation을 보존하기 위해 *길이 L 의 overlapping block 집합* (L ≈ √N_frames ≈ 39, 5 fps 기준 약 8 sec; Künsch [26] moving-block convention 으로 모든 시작 index i = 0,1,…,N−L 에 대해 block 정의) 에서 ⌈N/L⌉ 개의 block 을 *with-replacement* 추출 (B = 1,000 resamples) 한다. 각 resample에 대해 Δ_industrial − Δ_library 를 계산하여 percentile method (2.5%, 97.5%) 로 95% CI를 산출한다. CI 가 0을 포함하지 않으면 H-Gap *supported*. Künsch [26] 의 moving-block 권장 convention 을 따르며, 이는 본 도메인의 short-range temporal correlation (5–10 frame scale의 motion blur 군집·작업자 동선 군집) 을 정확히 보존한다.

**Secondary — Wilcoxon signed-rank (site-level).** n = 3 industrial · n = 3 library 의 site-level Δ pair (도메인 매칭은 frame budget로 정규화된 sample 단위) 에 대해 비모수 paired test를 수행. block bootstrap이 frame-level 가정 (block 내 stationarity) 에 의존하는 반면, site-level paired test는 site 를 i.i.d. 단위로 보는 conservative 검정으로 두 검정의 verdict 차이 자체가 §5.6 statistical conclusion validity 의 핵심 indicator가 된다.

**Tertiary (sensitivity only) — Per-frame naive paired bootstrap.** Independence 가정 위반 인지 하에 *상한 효과 크기 추정용* 으로만 보고된다. 본문 인용은 primary block bootstrap 결과로 통일하며, 세 검정 결과의 disagreement detail은 Appendix C에 병기한다.

**보조 — Stationary bootstrap (Politis & Romano [27]).** Block length 의 hyperparameter 민감도를 검증하기 위한 sensitivity check 로 사용. Primary verdict 와의 일치 여부를 §5.6 limitations 에 보고.

[Fig. 4: Effect size forest plot — metric (PSNR/SSIM/LPIPS/Chamfer/BEV IoU/Nav success) × {block bootstrap 95% CI primary, Wilcoxon site-level p-value secondary}; CI bar가 0을 가로지르면 not significant].

### 4.5 Mechanism Ablation

본 절은 cluster A/B/C 각각에 대해 frame-level mask on/off ablation을 수행하여 §3.5 의 mechanism 가설(H-Mechanism)을 causality 수준에서 검증한다. 본 ablation은 산업현장 3 site 전체에 대해 9 configurations 중 H-Best (P9) · H-Worst (P1) 두 configuration 으로 축소 수행한다 (full 9-config × 7-sub-cluster ablation은 frame budget 한계로 inviable).

**4.5a Stage 0 — Pilot Study.** I-1 site × {P1, P9} × {A.1 mask on, A.1 mask off} 의 2 × 2 cell pilot 을 먼저 실행하여 effect size (Cohen's d) 가 0.2 미만이면 ablation matrix를 재설계한다. 본 internal validity check는 §4.5b–f 의 본 실행 전 sample-efficient go/no-go gate 로 작동한다.

**4.5b Textureless Region Ablation — Cluster A.1.** Sobel gradient magnitude < τ_tex (frame 분포 30 percentile) 로 정의된 textureless mask 를 frame budget 의 0% / 25% / 50% / 75% / 100% 비율로 augmentation/blanking 하여 reconstruction quality 변화를 측정. Romanoni et al. [24] 의 TAPA-MVS 분석이 시사하는 textureless feature 한계가 hand-crafted SfM (P1의 M1 COLMAP [1] · SIFT [10]) 에서 catastrophic, deep prior (P9의 M7 MASt3R-SLAM [7]) 에서 robust 함을 사전 예측한다. [Fig. 5a: Quality (PSNR) vs textureless fraction curve, P1 vs P9 비교].

**4.5c Reflective Region Ablation — Cluster A.2.** HSV V-channel saturation peak 기반 specular highlight detection (standard image-processing primitive) 으로 reflective mask 를 정의하여 §4.5b 와 동일한 5-step ratio matrix 적용. Ref-NeRF [22] 가 강조한 view-dependent specular 모델링의 부재가 hand-crafted matching에서 더 큰 quality 저하를 가져올 것이 사전 예측이다. [Fig. 5b: Quality vs reflective fraction curve].

**4.5d 오염 Region Ablation — Cluster A.3.** Color variance + edge density anomaly segmentation [25] (MVTec AD anomaly 기준 차용)으로 mask 정의. 동일 5-step matrix. [Fig. 5c: Quality vs 오염 fraction curve].

**4.5d-aux Mask Cross-Report (Redundancy vs Collinearity).** §4.5b/c/d 의 세 sub-cluster mask (A.1 textureless / A.2 reflective / A.3 오염) 간 pairwise IoU 를 site별 + global 평균으로 보고. 평균 IoU < 0.2 → 세 mask 가 disjoint → §4.5b/c/d 는 independent evidence (redundancy by design 성공). 평균 IoU > 0.5 → mask 가 collinear → ablation effect 분리 불가능 → §5.5 limitations 에 명시. [Tab. 5: Pairwise IoU matrix (A.1, A.2, A.3) × site (I-1, I-2, I-3) + global mean].

**4.5e Dynamic Object Removal Ablation — Cluster B.1.** §3.2 (d) 의 SAM 2.1 / SAM 3 unified backend [13] 로 사전 생성된 binary exclusion mask 에 대한 on/off ablation. **Full-set comparison 정의 (sharp 집합 S 전체, |S| = §3.6 F4 의 N_frames = 1,500 정규화 후):** sharp 집합 S 와 mask 집합 M 은 §3.2 (d) 의 *독립 collection* 정의 (M ⊆ S 또는 S ⊆ M 가정 없음; skip_empty 와 manual sharp reclassification 의 두 비대칭 모두 정상) 를 따른다. ablation evidence 는 **intersection** I = {f : f ∈ S ∧ f ∈ M} 에 한정되며, 두 condition 은 다음과 같이 정의된다 — **Mask on:** ∀f ∈ I 에서 mask 영역 (작업자·이동 자재 등 dynamic instance pixel) 을 학습 frame 에서 제외; ∀f ∈ S \ I 는 그대로 학습에 포함 (mask 가 없거나 sharp 가 없으므로 제외할 영역 없음). **Mask off:** ∀f ∈ S 를 그대로 학습에 포함 (mask 영역 무시). Mask 집합 M 의 orphan frame (M \ S; sharp 가 사후 제거된 frame 의 mask) 은 학습 자체가 불가능하므로 두 condition 모두에서 자동 제외된다. 본 두 condition 에 대해 동일 site × method 의 reconstruction 품질과 pose ATE drift 를 비교한다. DynaSLAM [23] 류의 dynamic-aware pipeline 부재가 pose estimation drift 에 미치는 영향을 mask off condition 에서 측정. *주: |I| / |S| 비율 (intersection 의 frame coverage) 이 낮은 site (예: dynamic instance 가 드문 library control 또는 sharp manual reclassification 후 orphan 비율이 높은 site) 에서는 mask on vs off 의 effect size 가 attenuated 되어 관측될 수 있으며, 이는 §5.6 internal validity 의 mask-noise attenuation bias 항목으로 포섭된다 — site 별 |I| / |S| 와 |M \ S| / |M| 두 비율을 §4.5e 결과 표의 부수 column 으로 보고한다.* Mask 자체의 source bias 통제를 위해, primary mask (SAM 2.1 / SAM 3 backend) 와 *secondary mask* (YOLOv8-seg [14] instance segmentation) 의 IoU 일치도를 §5.6 internal validity 의 cross-method consistency check 로 보조 보고한다. [Fig. 6: Trajectory drift (ATE) vs dynamic object pixel fraction, P1 vs P9]. *비고:* Cluster B.2 (scale 변동) 는 frame-level mask 정의가 depth prior 를 추가로 요구하여 본 ablation 행렬에서 inviable 하므로 §5.5 limitations 의 future-work slot 으로 미룬다 — 본 논문은 B.2 에 대해서는 cluster prediction 만 §3.5 에 명시하고 ablation 검증은 수행하지 않는다.

**4.5f Low-light / Photometric Drift Ablation — Cluster C.** C.1 (low-light) 는 mean luminance < τ_lum 으로 정의된 frame 에 gamma 보정 또는 histogram equalization 적용 / 미적용 ablation. C.2 (비균질 조명) 는 frame 내 luminance variance > τ_var 영역에 luminance variance normalization 적용 / 미적용 ablation. 두 sub-cluster 결과는 별도 figure로 보고. [Fig. 7a: Quality vs mean luminance (C.1) / Fig. 7b: Quality vs luminance variance (C.2)].

### 4.6 Robot Navigation Evaluation (IsaacSim + Spot + RRT*)

본 절은 9 pipeline configurations 의 reconstruction 품질이 실제 sampling-based navigation 성공률로 어떻게 변환되는지를 IsaacSim + Spot + RRT* [18] harness 로 정량 측정한다.

**Run budget.** 9 configurations × 6 scenes (I-1, I-2, I-3, L-1, L-2, L-3) × K start–goal pairs 의 직조에서 default K = 20 시 총 1,080 runs 가 산출되며, 1 run 평균 2 분 시뮬레이션 wall-clock 으로 약 36 시간 (single-IsaacSim instance 기준) 소요된다. IsaacSim 의 GPU-parallel batch sim API 적용 시 4-GPU 환경에서 ~10 시간으로 단축.

**부피 감축 — Option B (tiered) default.** Pilot K = 5 (= 9 × 6 × 5 = 270 runs, 약 9 시간) 의 결과 분포를 먼저 보고 outlier configuration (mean ± 1.5 σ 이탈) 에 한해 K = 20 으로 확장. 단, 사전등록 가설 의 충실성을 위해 H-Best (P9) 와 H-Worst (P1) 두 configuration 은 *어떤 결과 분포에도 무관하게* K = 20 을 보장한다 (총 240 runs 사전 commit).

**Result reporting.** [Tab. 3: Configuration × {success rate, avg path length (m), collision count per run, RRT* planning time (sec)}, n_runs = K × 6 scenes × 9 configurations]. [Fig. 8: Representative navigation trajectories — H-Best (P9) vs H-Worst (P1) side-by-side, 동일 start–goal pair].

**Reconstruction-Navigation Correlation.** Configuration 단위 (n = 9) 에서 BEV occupancy IoU 와 RRT* success rate 의 Pearson r · Spearman ρ 를 산출하여 reconstruction quality 가 navigation 성공률을 얼마나 explain 하는지를 보고. 본 correlation 은 §5.4 의 design principle (C3) "domain-method matching" 의 결정적 근거가 된다.

> *(§4 → §5 transition)* 다음 장에서는 위 결과를 §2의 문헌과 dialogue시키고, 도메인-메서드 매칭 디자인 원칙(C3)을 도출한다.

---

## §5 Discussion

본 장은 §4 의 비교 평가 및 ablation 결과를 §2 의 문헌과 dialogue시켜 (i) 사전등록 가설별 verdict (§5.1), (ii) cluster A/B/C 메커니즘 단위의 인과적 설명 (§5.2), (iii) representation choice의 도메인-적합성 해석 (§5.3) 을 정리하고, (iv) actionable design principle C3 (§5.4) 을 도출한다. 끝으로 (v) 정직한 limitations (§5.5) 와 (vi) Wohlin et al. [28] 4-threat 분류 기반 validity 자기비판 (§5.6) 을 보고한다.

### 5.1 사전등록 가설 검증 결과 요약

[Tab. 4: H 검증 verdict — H-Best (P9 = M7 MASt3R-SLAM [7] + M9 2DGS [9]) / H-Worst (P1 = M1 COLMAP [1] + M8 3DGS [8]) / H-Gap (Δ_industrial > Δ_library) / H-Mechanism A·B·C 각각, verdict 컬럼 = {supported, partial, refuted, inconclusive}, evidence cell = §4.x figure/table 참조].

본 verdict 4-class 구분은 사전등록 plain text 와 관측 ranking 간 일치도, 그리고 §4.4 block bootstrap CI 의 zero-crossing 여부로 결정된다. 사전등록 ranking 과 관측 ranking 의 *완전 일치* + CI 가 0을 포함하지 않음 → *supported*; 일부 metric 에서만 일치 → *partial*; 반대 ranking → *refuted*; CI 가 0을 가로지름 → *inconclusive*. 본 4-class 구분은 cherry-picking 또는 HARK (hypothesizing after results are known) 의여지를 사전 차단하는 본 논문의 pre-registration 정직성 commitment 의 직접 이행이다 (§1.4 참조).

만약 H-Best 또는 H-Worst 가 *refuted* 로 판명될 경우, 본 §5.2–§5.3 의 mechanism 설명은 부분적 또는 전반적으로 재해석되며, 그 경우의 후보 원인(예: industrial 3 site 의 cluster 강도가 deep prior 의 학습 분포에 우연히 가까웠을 가능성, MASt3R-SLAM 의 native intrinsics 가정 불일치 등)을 §5.5 limitations 에 직접 등록한다.

### 5.2 Why Deep Prior > Hand-crafted in Industrial Domain

본 절은 §4.5 의 cluster-wise ablation 이 (사전등록 통과 시) 보여주는 deep prior 우위의 메커니즘적 설명을 §2.2–§2.3 의 문헌과 dialogue 시킨다.

**Cluster A (Visual Ambiguity).** Hand-crafted SIFT [10] 기반 SfM (COLMAP [1], GLOMAP [2]) 은 keypoint *repeatability* — 같은 3D 점이 다른 view 에서 같은 descriptor 로 검출되는 빈도 — 에 의존한다. 그러나 textureless (A.1) · reflective (A.2) · 오염 (A.3) 영역에서는 gradient sparsity · view-dependent appearance · texture anomaly 가 모두 repeatability 를 붕괴시킨다. Romanoni et al. [24] 가 TAPA-MVS 에서 보고한 textureless 영역의 dense matching 부재가 본 ablation 의 A.1 row 에 직접 대응하며, Ref-NeRF [22] 의 specular highlight 모델링 필요성이 A.2 의 정량 ablation 으로 검증된다. 반면 deep matching (DUSt3R [3], MASt3R [4]) 과 deep SLAM (MASt3R-SLAM [7]) 은 dense correspondence regression 으로 sparse keypoint 의존성 자체가 없어 cluster A 의 세 sub-cluster 모두에서 robust 한 pose estimation 을 유지한다.

**Cluster B (Scene Non-staticity).** Classical SfM 의 epipolar geometry 가정은 *static scene* 을 전제하며, dynamic instance (B.1 — 작업자, 이동 자재) 는 outlier injection 으로 catastrophic pose estimation failure 를 유발한다. DynaSLAM [23] 류의 dynamic-aware SLAM 은 별도 mask pipeline 으로 이 가정 위반을 우회하며, deep SLAM 은 학습 데이터 분포에 dynamic instance 시나리오가 포함되어 robust 한 inductive bias 를 학습한 결과를 보여준다. Scale 변동 (B.2) 의 경우 deep depth prior 가 monocular depth 의 absolute scale ambiguity 를 학습 prior 로 일부 해소하는 반면 hand-crafted SfM 은 매 frame 의 epipolar constraint 에만 의존하여 scale 일관성을 잃기 쉽다.

**Cluster C (Photometric Drift).** Hand-crafted feature 의 photometric invariance (e.g., SIFT [10] 의 gradient 정규화) 는 illumination *uniform shift* 에는 강건하나 산업현장의 비균질 조명 (C.2) — 직사 스포트라이트 + 형광등 mixed 환경 — 에서는 saturation peak 와 shadow boundary 가 view 마다 다르게 나타나 invariance 가 위반된다. Deep network 의 photometric augmentation 학습 leverage (color jitter, gamma 변동) 가 cluster C 에서 deep prior 의 우위를 형성하는 학습 데이터 측 inductive bias 로 해석된다.

단, 본 설명은 industrial OOD (out-of-distribution) 측면을 부정하지 않는다 — deep model 도 학습 분포 밖의 산업현장 (예: 극한 저조도, 극한 반사) 에서 한계가 있으며, 이 한계는 §5.5 에 후술된다.

### 5.3 Why 2DGS > 3DGS in Industrial Domain

본 절은 §4.3 의 representation isolation pair (P1↔P2 = COLMAP × {3DGS, 2DGS}; P8↔P9 = MASt3R-SLAM × {3DGS, 2DGS}) 비교가 (사전등록 통과 시) 보여주는 2DGS 우위의 도메인-적합성 해석이다.

산업현장의 dominant geometry 는 *평면적* 이다 — 벽 · 바닥 · 기계 외관 · 통로의 측벽이 모두 planar 또는 piecewise-planar surface 를 형성한다. 2DGS [9] 의 surface-aligned 2D disk primitive 는 oriented disk 의 normal field 가 진짜 surface normal 에 가까이 align 되도록 학습되어 본 planar dominant 환경의 inductive bias 와 정합한다. 반면 3DGS [8] 의 anisotropic 3D Gaussian 은 더 일반적인 표현력을 가지지만 sparse view + planar dominant 환경에서는 *over-parameterized* — 같은 평면을 여러 layer 의 thin Gaussian 으로 표현하여 view-consistent 하지만 surface normal 이 정의되지 않는 결과를 만들 수 있다.

이 over-parameterization 은 본 논문의 navigation 단계 (§3.7, §4.6) 에서 직접 비용으로 전환된다. BEV occupancy grid 생성 시 z ∈ [0.1 m, 2.0 m] 의 height threshold 가 적용되는데, 3DGS 의 thin-layer 결과는 single planar 표면 주변에 다층 Gaussian 분포를 만들어 BEV cell 의 occupancy false-positive 를 증가시킨다. 반면 2DGS 의 surface-aligned 결과는 단일 disk 가 정확히 height threshold 의 경계에 위치하여 false-positive 가 감소한다. 결과적으로 동일 pose method 입력에서도 representation 차이만으로 BEV IoU (§4.2 M2) 가 의미 있는 차이를 보이며, 이는 §4.6 의 reconstruction-navigation correlation 에서 BEV IoU vs RRT* success rate 의 양의 상관관계로 관측된다 (TBD).

### 5.4 Design Principle (C3) — Domain-Method Matching

본 논문의 §4 정량 결과와 §5.2–§5.3 의 메커니즘 해석은 다음 단일 design principle 로 압축된다.

> **Box 5.4 — Design Principle C3 (Domain-Method Matching).** 산업현장 camera-only 3D 재구성 + 로봇 자율주행 시나리오에서는 (i) deep-prior pose estimation (MASt3R-SLAM [7] 또는 DPV-SLAM [6]) 과 (ii) planar-prior representation (2DGS [9]) 의 조합을 권장한다. Hand-crafted SfM (COLMAP [1], GLOMAP [2]) 과 isotropic 3D representation (3DGS [8]) 의 조합은 보디캠 산업현장 입력에서 권장되지 않는다.

본 design principle 은 단순한 ranking 결론이 아니라 *도메인 mechanism 식별 → 메커니즘에 견디는 prior 선택* 이라는 reasoning loop 의 instantiation 이다. 즉, 일반 indoor 벤치마크 (ScanNet [11], Replica [12]) 의 SOTA ranking 보다 도메인 mechanism cluster 진단이 method 선택의 *더 신뢰할 수 있는* 기준이라는 메타-원칙을 본 논문이 산업현장 사례로 입증한 셈이다.

### 5.5 Limitations

본 논문의 결론은 다음 6가지 한계를 정직하게 명시한다.

**(L1) 사이트 수 n = 3.** Industrial · Library 각각 3 site 로 일반화에 한계가 있다. §4.4 의 block bootstrap 은 frame-level inference 를 회복하지만 site-level external validity 는 별개 issue 로 남는다. Mitigation: future work 의 site 확장 (§6.2).

**(L2) 단일 보디캠.** Multi-cam fusion (예: 작업자 보디캠 + 천장 고정 카메라) 미포함. Multi-view geometry 의 강건성을 sensor diversity 로 보강할 여지는 본 논문 범위 밖이다.

**(L3) Weather / season 미반영.** 외부 통로 (I-2) 의 우천 · 결로 · 직사광선 등 photometric drift extreme 시나리오는 single recording session 으로 인해 평가되지 않았다.

**(L4) Single GPU class (RTX 4090).** 분산 학습 또는 다른 GPU 클래스 (A100, H100) 에서의 결과 차이는 미검증.

**(L5) Hyperparameter default 사용.** 각 atomic method 의 best-tuned 성능은 의도된 공정성 trade-off 로 미평가 (§3.6 F2). Configuration 단위 best-tuning 은 §6.2 의 future work 에서 follow-up 가능.

**(L6) Real-world deployment 미검증.** §4.6 의 navigation 평가는 IsaacSim 시뮬레이션에 한정되며, 실제 Spot 로봇 산업현장 배포의 sim-to-real gap 은 검증되지 않았다.

**(L7) Human-in-the-loop reclassification 의 reproducibility 한계.** §3.2 (e) 의 dashboard 기반 manual reclassification (sharp/blur/drop/dup bucket 재할당, keyboard shortcut S/B/D) 은 작업자 (저자) 의 시각 판단에 의존한다. 본 manual 단계의 reproducibility 를 보강하기 위해 (i) 최종 bucket assignment manifest 는 §3.6 F5 의 공개 commitment 에 포함되어 publication 시 배포되며, (ii) 모든 reclassification 은 가역적 API call 로 기록되어 audit trail 이 보존된다. 그러나 *동일 video 재처리 시 다른 annotator 의 bucket assignment 가 본 논문 결과를 어느 정도 재현하는지* 의 inter-annotator agreement 는 본 논문 범위 밖이며, future work 의 reproducibility study 항목으로 등록된다 (§6.2 F4 long-term temporal consistency 의 sub-slot).

### 5.6 Threats to Validity

본 절은 Wohlin et al. [28] 의 4-threat 분류 (Internal / External / Construct / Conclusion) 와 Runeson & Höst [29] 의 case study guideline 을 framework 로 사용하여 본 논문의 방법론적 자기비판을 정리한다.

**Internal validity.** §4.5 ablation 의 mask 생성 알고리즘은 ground-truth mask 가 없으므로 *cross-method consistency* (primary: §3.2 (d) SAM 2.1 / SAM 3 backend [13] vs secondary: YOLOv8-seg [14] instance segmentation 의 mask IoU; §4.5e 참조) 와 *cross-sub-cluster IoU* (§4.5d-aux Tab. 5) 로 부분적으로 보완된다. 그러나 mask 자체의 noise 가 ablation effect 의 attenuation bias 로 작용할 가능성은 남는다. 또한 §3.2 (e) 의 human-in-the-loop reclassification 단계 (L7) 가 mask 분포 자체에 second-order 영향을 줄 수 있으므로, 본 단계의 audit trail manifest 가 §3.6 F5 공개 commitment 에 포함된다.

**External validity.** Industrial 3 site (I-1 생산라인 · I-2 외부 통로 · I-3 기계실) 는 산업현장 전체 분포를 대표하지 못한다. Runeson & Höst [29] 의 case study external validity guideline 에 따라 본 논문은 결론을 *case-bounded* 로 한정하며, 일반화 commitment 는 §6.2 의 outdoor industrial site 확장으로 미룬다.

**Construct validity.** "Navigation suitability" 를 RRT* [18] success rate 로 측정한 선택은 다른 planner (PRM, A* on BEV, learning-based planner) 에서 다른 결과를 만들 수 있다. 본 논문의 RRT* 선택은 *deterministic + reproducible + GT-가용* 한 단일 baseline 으로의 commitment 이며 multi-planner 비교는 future work 이다.

**Conclusion (Statistical) validity.** n = 3 site 에서 paired bootstrap 은 frame-level 만 inference 회복하고 site-level 은 conservative Wilcoxon 으로 보강된다 (§4.4). 두 검정의 verdict 가 다를 경우 (예: block bootstrap supported + Wilcoxon inconclusive) 본문은 *primary 가 결정 권한* 으로 commit하되 disagreement 자체를 §5.6 에 inline 으로 보고한다. Künsch [26] block length L 의 hyperparameter sensitivity 는 Politis & Romano [27] stationary bootstrap sensitivity 와 비교하여 Appendix C 에서 별도 평가된다.

> *(§5 → §6 transition)* 마지막 장에서 가장 중요한 발견과 향후 연구 방향을 정리한다.

---

## §6 Conclusion

### 6.1 Summary

본 논문은 산업현장 보디캠 영상이라는 단일 도메인에서 9 atomic 3D 재구성 방법론 [1]–[9] 의 9 pipeline configurations (P1–P9) 를 일관된 공정성 프로토콜 하에 비교하고, 그 결과를 BEV occupancy + IsaacSim + Spot/RRT* [18] 까지 연결한 end-to-end 평가 첫 사례를 보고하였다. 본 연구의 세 기여는 다음과 같다. **C1 (β·비교평가):** 9 atomic methods × 2 domain 사전등록 비교 — 임의의 사후 cherry-picking 을 차단하는 H-Best (P9 = MASt3R-SLAM [7] + 2DGS [9]) · H-Worst (P1 = COLMAP [1] + 3DGS [8]) · H-Gap (Δ_industrial > Δ_library) · H-Mechanism (cluster A/B/C 인과적 분리) 의 falsifiable framework. **C2 (γ·시스템):** capture → preprocess (FFmpeg aspect-locked crop / Laplacian variance 4-bucket [15] / dHash dedup / SAM 2.1 / SAM 3 unified exclusion mask [13] + YOLOv8-seg [14] sensitivity / human-in-the-loop dashboard) → camera mapping → representation → mesh ([9] native / SuGaR [17] / Poisson [16]) → BEV occupancy → IsaacSim → RRT* navigation 의 6 stage end-to-end pipeline 구현 및 공개 commitment. **C3 (δ·디자인 원칙):** *domain mechanism 진단 → 메커니즘에 견디는 prior 선택* reasoning loop 을 산업현장 사례로 instantiate한 "deep-prior pose + planar-prior representation" design principle (§5.4 Box). 핵심 finding 한 줄: *Δ_industrial 이 Δ_library 대비 (TBD) 배 크며, 그 격차는 cluster A (textureless · reflective · 오염) [22], [24], [25] 메커니즘으로 가장 강하게 설명된다* (§4.4, §4.5 결과 산출 후 확정).

### 6.2 Future Work

본 논문의 한계 (§5.5) 와 외부타당도 commitment (§5.6) 를 후속 연구로 확장할 다섯 방향을 제시한다.

**(F1) Outdoor industrial site 확장.** 건설현장 · 플랜트 · 야외 점검 시설 등 weather · season 변동이 포함된 산업현장으로 site 수를 확장하여 L1 (n=3) · L3 (weather 미반영) 한계를 해소.

**(F2) Multi-modal sensor fusion.** 보디캠 RGB + IMU + opportunistic LiDAR/depth 의 융합 시 deep-prior pose 의 강건성이 sensor diversity 와 어떻게 상호작용하는지 정량 평가.

**(F3) On-device real-time deployment.** Spot 로봇 onboard NVIDIA Jetson 급 edge 디바이스에서 9 configurations 의 real-time 가용성 (FPS, latency, power) 측정 — IsaacSim sim-to-real gap (L6) 의 직접 검증.

**(F4) Long-term temporal consistency.** 동일 산업현장에서 월 단위 · 분기 단위 multi-session 영상을 수집하여 site change tracking 과 incremental map update 의 method 적합성 비교.

**(F5) Multi-robot collaborative mapping.** 작업자 보디캠 + 천장 고정 카메라 + 두 번째 Spot 로봇의 영상을 비동기 fusion 하여 single-cam 한계 (L2) 를 해소한 multi-agent 산업현장 mapping 의 가능성 탐색.

---

## References

> IEEE numeric style. Source: [LIT_REVIEW.md §2 정식 Annotated Bibliography](LIT_REVIEW.md#2-정식-annotated-bibliography-ieee-형식). DOI 검증 완료 (15/29 batch; 2026-05-12 patch log).

[1] J. L. Schönberger and J.-M. Frahm, "Structure-from-Motion Revisited," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, Las Vegas, NV, 2016, pp. 4104–4113. doi: https://doi.org/10.1109/CVPR.2016.445

[2] L. Pan, D. Baráth, M. Pollefeys, and J. L. Schönberger, "Global Structure-from-Motion Revisited," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2407.20219.

[3] S. Wang, V. Leroy, Y. Cabon, B. Chidlovskii, and J. Revaud, "DUSt3R: Geometric 3D Vision Made Easy," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2024, arXiv:2312.14132.

[4] V. Leroy, Y. Cabon, and J. Revaud, "Grounding Image Matching in 3D with MASt3R," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2406.09756.

[5] Z. Teed and J. Deng, "DROID-SLAM: Deep Visual SLAM for Monocular, Stereo, and RGB-D Cameras," in *Proc. Advances in Neural Information Processing Systems (NeurIPS)*, 2021, arXiv:2108.10869.

[6] L. Lipson, Z. Teed, and J. Deng, "Deep Patch Visual SLAM," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2408.01654.

[7] R. Murai, E. Dexheimer, and A. J. Davison, "MASt3R-SLAM: Real-Time Dense SLAM with 3D Reconstruction Priors," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2025, arXiv:2412.12392, pp. 16695–16705.

[8] B. Kerbl, G. Kopanas, T. Leimkühler, and G. Drettakis, "3D Gaussian Splatting for Real-Time Radiance Field Rendering," *ACM Trans. Graphics (SIGGRAPH)*, vol. 42, no. 4, 2023. doi: https://doi.org/10.1145/3592433

[9] B. Huang, Z. Yu, A. Chen, A. Geiger, and S. Gao, "2D Gaussian Splatting for Geometrically Accurate Radiance Fields," in *Proc. ACM SIGGRAPH*, 2024. doi: https://doi.org/10.1145/3641519.3657428

[10] D. G. Lowe, "Distinctive Image Features from Scale-Invariant Keypoints," *Int. J. Computer Vision (IJCV)*, vol. 60, no. 2, pp. 91–110, 2004. doi: https://doi.org/10.1023/B:VISI.0000029664.99615.94

[11] A. Dai, A. X. Chang, M. Savva, M. Halber, T. Funkhouser, and M. Nießner, "ScanNet: Richly-Annotated 3D Reconstructions of Indoor Scenes," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2017. doi: https://doi.org/10.1109/CVPR.2017.261

[12] J. Straub *et al.*, "The Replica Dataset: A Digital Replica of Indoor Spaces," arXiv:1906.05797, 2019.

[13] N. Ravi *et al.*, "SAM 2: Segment Anything in Images and Videos," arXiv:2408.00714, 2024.

[14] G. Jocher, A. Chaurasia, and J. Qiu, "Ultralytics YOLOv8," GitHub: ultralytics/ultralytics, version 8.0.0, 2023. [Online]. Available: https://github.com/ultralytics/ultralytics

[15] S. Pertuz, D. Puig, and M. A. García, "Analysis of Focus Measure Operators for Shape-from-Focus," *Pattern Recognition*, vol. 46, no. 5, pp. 1415–1432, 2013. doi: https://doi.org/10.1016/j.patcog.2012.11.011

[16] M. Kazhdan, M. Bolitho, and H. Hoppe, "Poisson Surface Reconstruction," in *Proc. Symp. Geometry Processing (SGP)*, 2006, pp. 61–70.

[17] A. Guédon and V. Lepetit, "SuGaR: Surface-Aligned Gaussian Splatting for Efficient 3D Mesh Reconstruction and High-Quality Mesh Rendering," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2024, arXiv:2311.12775.

[18] S. Karaman and E. Frazzoli, "Sampling-based Algorithms for Optimal Motion Planning," *Int. J. Robotics Research (IJRR)*, vol. 30, no. 7, pp. 846–894, 2011. doi: https://doi.org/10.1177/0278364911406761

[19] F. Bosché, "Automated Recognition of 3D CAD Model Objects in Laser Scans and Calculation of As-Built Dimensions for Dimensional Compliance Control in Construction," *Adv. Engineering Informatics*, vol. 24, no. 1, pp. 107–118, 2010. doi: https://doi.org/10.1016/j.aei.2009.08.006

[20] J. Xue, X. Hou, and Y. Zeng, "Review of Image-Based 3D Reconstruction of Building for Automated Construction Progress Monitoring," *Applied Sciences*, vol. 11, no. 17, p. 7840, 2021. doi: https://doi.org/10.3390/app11177840

[21] A. Sun, X. An, P. Li, M. Lv, and W. Liu, "Near Real-Time 3D Reconstruction of Construction Sites Based on Surveillance Cameras," *Buildings*, vol. 15, no. 4, p. 567, 2025. doi: https://doi.org/10.3390/buildings15040567

[22] D. Verbin, P. Hedman, B. Mildenhall, T. Zickler, J. T. Barron, and P. P. Srinivasan, "Ref-NeRF: Structured View-Dependent Appearance for Neural Radiance Fields," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2022. doi: https://doi.org/10.1109/CVPR52688.2022.00541

[23] B. Bescos, J. M. Fácil, J. Civera, and J. Neira, "DynaSLAM: Tracking, Mapping, and Inpainting in Dynamic Scenes," *IEEE Robotics and Automation Letters (RA-L)*, vol. 3, no. 4, pp. 4076–4083, 2018. doi: https://doi.org/10.1109/LRA.2018.2860039

[24] A. Romanoni and M. Matteucci, "TAPA-MVS: Textureless-Aware PAtchMatch Multi-View Stereo," in *Proc. IEEE/CVF Int. Conf. Computer Vision (ICCV)*, 2019. doi: https://doi.org/10.1109/ICCV.2019.01051

[25] P. Bergmann, M. Fauser, D. Sattlegger, and C. Steger, "MVTec AD — A Comprehensive Real-World Dataset for Unsupervised Anomaly Detection," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2019. doi: https://doi.org/10.1109/CVPR.2019.00982

[26] H. R. Künsch, "The Jackknife and the Bootstrap for General Stationary Observations," *Annals of Statistics*, vol. 17, no. 3, pp. 1217–1261, 1989. doi: https://doi.org/10.1214/aos/1176347265

[27] D. N. Politis and J. P. Romano, "The Stationary Bootstrap," *J. American Statistical Association*, vol. 89, no. 428, pp. 1303–1313, 1994. doi: https://doi.org/10.1080/01621459.1994.10476870

[28] C. Wohlin, P. Runeson, M. Höst, M. C. Ohlsson, B. Regnell, and A. Wesslén, *Experimentation in Software Engineering*, 2nd ed. Berlin, Germany: Springer, 2012.

[29] P. Runeson and M. Höst, "Guidelines for Conducting and Reporting Case Study Research in Software Engineering," *Empirical Software Engineering*, vol. 14, no. 2, pp. 131–164, 2009. doi: https://doi.org/10.1007/s10664-008-9102-8

---
