# Paper Outline + Evidence Map

> ARS `academic-paper` `outline-only` mode 산출물
> 생성일: 2026-05-11
> Upstream: [CHAPTER_PLAN.md](CHAPTER_PLAN.md) (plan mode 결과)
> Oversight: **High** / Spectrum: **Balanced**

---

## Patch Log

| 일자 | 패치 | 영향 섹션 |
|---|---|---|
| 2026-05-11 (rev2) | Tier 1+2 audit 반영 (8개 fix) | §1.2, §3.3, §3.5, §3.6, §3.7, §4.3, §4.4, §4.5, §4.6, §5.2 |
| 2026-05-11 (rev2 후속) | CHAPTER_PLAN.md cluster A/B/C sync 완료 | CHAPTER_PLAN INSIGHT 3, §3.5, §4.5 |
| 2026-05-11 (rev2 후속) | §3.3 Option β 확정 — 9 pipeline configurations (P1–P9) Table 1b fix | §3.3 Table 1b, §4.3, §4.6 |
| 2026-05-11 (rev2 승인) | **User approval 완료 — outline 단계 종료** | Quality Gate |
| 2026-05-11 (lit-review 후속) | §4.4 bootstrap 출처 Künsch89 [LR-26] 귀속 정정 + Politis94 [LR-27] sensitivity로 분리 | §4.4 |
| 2026-05-11 (lit-review 후속) | §2.5 [20] placeholder 해소 — Braun21 [20] + Jiang25 [21] 듀얼 인용 확정; §F·§G refs [21]~[26] → [22]~[27] 재번호 | §2.5, Evidence Map |
| 2026-05-11 (lit-review 후속) | §5.6 Validity framework 확정 — Wohlin12 [LR-28] primary + Runeson09 [LR-29] case study secondary 채택; 마지막 [TBD] 해소 | §5.6, Evidence Map |
| 2026-05-11 (citation-check) | **[CRITICAL fabrication 정정]** [20] Braun→**Xue/Hou/Zeng** + [21] Jiang→**Sun/An/Li/Lv/Liu** (DOI/title/venue 정확, 저자명만 WebSearch 오인) — CrossRef + OpenAlex 이중 검증 후 본문·Evidence Map 정정 | §2.5, Evidence Map |
| 2026-05-11 (citation-check) | §2.1 본문 [25]→[24] 정정 (textureless 한계 claim에 Bergmann19/Künsch89 ref 부정합 → Romanoni19 TAPA-MVS로 보정) | §2.1 |
| 2026-05-12 (citation-check Tier 2) | LIT_REVIEW.md ref list에 DOI 15건 batch insert ([1][8][9][10][11][15][18][19][22][23][24][25][26][27][29]) — IEEE submission 완전 준수 기여 | LIT_REVIEW refs |
| 2026-05-12 (experiment-setup Tier 1) | `experiments/` 디렉토리 신규 — Pilot-first scope로 M1/M7/M8/M9 4개 Dockerfile + 4 README + data layout 규약 + 3 verify/download script (총 13파일). Base image `nvidia/cuda:11.8.0-devel-ubuntu22.04`, PyTorch 2.1.0+cu118, `TORCH_CUDA_ARCH_LIST="8.9"` (RTX 4090 × 4). P1 (H-Worst) / P9 (H-Best) end-to-end orchestration은 Tier 2 deferred. | experiments/ (신규), §3.3 P1/P9 |
| 2026-05-12 (experiment-setup Tier 1 hotfix) | M8 3DGS / M9 2DGS Dockerfile에 `--no-build-isolation` 추가 (`pip install ./submodules/*`). PEP 517 build isolation이 setup.py에서 `import torch`를 격리시켜 빌드 실패하던 이슈 해소. Known Issues에도 패턴 등재. | docker/m8_3dgs, docker/m9_2dgs |
| 2026-05-12 (experiment-setup Tier 2) | `experiments/` Tier 2 추가 (7파일, 1,393 lines) — P1/P9 end-to-end orchestration (`run_pipeline_p1.sh`, `run_pipeline_p9.sh`, `run_pilot_i1.sh`) + M7→COLMAP adapter (`mast3r_slam_to_colmap.py`, TUM→COLMAP text 변환·quaternion·pose convention reversal 포함) + `compute_metrics.py` (wall-time / n_gaussians / PSNR/SSIM/LPIPS) + adapters/scripts README. Fairness frame budget normalization·VRAM peak·Chamfer/BEV-IoU/RRT* metrics는 Tier 3 deferred. | experiments/ (확장), §3.3 P1/P9, §3.7 mesh extraction interface |
| 2026-05-12 (write §3) | PAPER_DRAFT.md 신규 — §3 Pipeline Design 초안 작성 (§3.1–§3.7, ~1,400 단어 target). IEEE numeric inline citation ([1]–[29], LIT_REVIEW.md 매핑) + `[Fig./Tab./Alg. N: caption]` placeholder 정책. Chapter별 순차 진입; 다음 §4 Experiments 대기. | PAPER_DRAFT.md §3 |
| 2026-05-12 (write §1–§6 전체 본문) | PAPER_DRAFT.md 6 chapter 본문 초안 완성 — §1 (827) / §2 (888) / §3 (1,819) / §4 (1,754) / §5 (1,473) / §6 (376) = 본문 누적 7,137 단어 (target 6,340 대비 +12.6%, KCI 공학 8–12 page 범위 내). IEEE numeric 인용 [1]–[27] + Fig/Tab/Alg placeholder. Front/back matter (abstract · references · appendix) 미작성. | PAPER_DRAFT.md §1–§6 전체 |
| 2026-05-12 (/ars-abstract) | Bilingual abstract + keywords 작성 — KR 236 단어 (target 250, -6%) + EN 251 words (target 250, ±0%). 사전등록 가설 H-Best/H-Worst/H-Gap/H-Mechanism 4종 명시 + C1/C2/C3 contribution 압축 + 결론은 falsifiable framework 수준에서 기술 (실측 TBD). Keywords KR/EN 각 7개. PAPER_DRAFT Front Matter 완성. | PAPER_DRAFT.md Front Matter |
| 2026-05-12 (revision pass Tier 1+2) | Severity-tiered audit 후 7-fix 일괄 patch — T1.1 H-Mechanism narrow (claim-evidence mismatch 해소: P9-vs-P1 representative 검증 + deep-prior 전체 일반화 §5.2 으로 분리) / T1.2 Künsch [26] moving-block overlapping convention 정정 / T1.3 §3.7 stage 번호를 §3.1 6-stage 와 정렬 (5a/5b/6a/6b) / T2.1 sparse Poisson [16] future-work reference slot 명시 / T2.2 §4.5 cluster B.2 ablation 제외 disclaimer / T2.3 Chamfer reference mesh 도메인별 정의 (library P9-mesh = low-bar / industrial = inter-method diagnostic only) / T2.4 §4.5e mask on/off wording 명시. | PAPER_DRAFT §1.4·§3.7·§4.2·§4.4·§4.5e |
| 2026-05-12 (References import + /ars-citation-check) | LIT_REVIEW.md → PAPER_DRAFT.md References section import 후 IEEE numeric integrity audit — orphan 0 / unused 0 / gap 0. 3-fix patch: **C1.1** §4.5c [22] HSV detection mis-attribution 정정 ("standard image-processing primitive" 으로 명시; Ref-NeRF [22] 인용은 view-dependent specular claim 으로만 유지) / **C2.1** §3.7 [9] §3.3 specific section number 제거 (검증 불가) / **C2.2** [5] DROID-SLAM 에 arXiv:2108.10869 추가 (NeurIPS 2021 entry 통일성). | PAPER_DRAFT References + §3.7·§4.5c |
| 2026-05-12 (trajectory B prep — pilot 진입 도구) | Pilot 실행 4-step 도구 준비 — (1) `experiments/adapters/colmap_to_intrinsics.py` (P1 self-calib → site 공유 OPENCV intrinsics JSON, 6 COLMAP camera model 지원; txt/bin smoke pass) + adapters/README.md §2 추가. (2) `experiments/scripts/reorganize_frames.sh` (raw PNG site/run nested → ARS layout symlink, 6 site × 1 run; smoke pass). (3) `experiments/RUN_PILOT.md` (학교 서버 `/data/minsuh/experiment/` 환경 변수 + 0–9 step 일괄 launch 가이드 + wall-time table). (4) Task list 5-step (intrinsics adapter ✓ / data layout 파악 ✓ / reorganize 스크립트 ✓ / 경로 migration ✓ / **pilot launch — 사용자 학교 서버 측 실행 대기**). | experiments/ (3 new files) |
| 2026-05-13 (sharp/mask split 반영) | 사용자 video-to-image 모듈이 `{site}/{run}/{sharp,mask}/*.png` 두 sub-folder 출력 (mask = SAM2/YOLO 계 dynamic instance mask, sharp ↔ mask 1:1 파일명 매칭) 확인 → 3-file 갱신: (1) `data/README.md` §2 에 `frames/` (sharp 대응) + `masks/` (mask 대응) layout 정의 추가 + 1:1 매칭 규약 명시 + §3.2 (c) preprocessing 사전통합 노트. (2) `scripts/reorganize_frames.sh` 가 sharp→frames / mask→masks 두 sub-folder 각각 symlink (edge case: sharp만 / mask만 / 둘 다 / 둘 다 없음 4가지 smoke pass) + `--sharp-dir / --mask-dir / --skip-mask` 플래그 추가. (3) `RUN_PILOT.md` §3 갱신 — sharp/mask 분리 layout 명시 + mask 사용 정책 (P1/P9 primary 는 frames/ 만, §4.5e cluster B.1 ablation 에서만 masks/ 활성화). 본 변경은 PAPER §3.2 (c) 의 "본 논문 (구현체) 에서는 video-to-image preprocessing 모듈에 SAM2/YOLO 가 사전 통합" 사실 반영 — 본문 wording 갱신은 PAPER_DRAFT 후속 patch 에서 검토. | experiments/data/README.md · scripts/reorganize_frames.sh · RUN_PILOT.md |
| 2026-05-13 (§3.2 4-sub-stage + dedup 반영) | 사용자 video-to-image 전처리 모듈 5 기능 (비디오 불러오기 / frame 나누기 / blur 자동삭제 / 유사도 기준 중복제거 / masking 처리) 사전 통합 사실을 PAPER §3.2 본문에 정식 반영. (1) **PAPER_DRAFT §3.2** 3 sub-stage → 4 sub-stage 재구성 — (a) Frame extraction (FPS) / (b) Sharpness-based blur removal [15] / (c) **Similarity-based deduplication 신규 sub-stage** (보디캠 정지·저속 구간 visually redundant frame 제거) / (d) Masking automation [13][14] + Alg. 1 pseudocode 4-stage 갱신 + §3.6 F4 frame budget 1,500 정의를 "(a)–(c) 통과 후 effective frame 수" 로 명시. (2) **RUN_PILOT.md §3** 에 사용자 모듈 5-기능 → §3.2 4 sub-stage 매핑 테이블 추가 + frame budget 확인 ad-hoc 스크립트 (§3.5) 추가. (3) **data/README.md §2** 에 사용자 모듈 5-기능 명시 + frames/ effective N 정의. | PAPER_DRAFT §3.2·§3.6 / experiments/RUN_PILOT.md·data/README.md |
| 2026-05-13 (§3.2 정밀 사양 5-위치) | 사용자 video-to-image 모듈 상세 사양 6 항목 (FFmpeg aspect-lock / 4-bucket {sharp,blur,drop,dup} / 8×8 dHash + Hamming / SAM 2.1·SAM 3 unified backend / human-in-the-loop React+MUI dashboard / binary exclusion mask semantics) PAPER 5 위치 일괄 patch — **§3.2** 정밀화 + (e) human-in-the-loop verification sub-stage 신규 + Alg. 1 5-stage 갱신 + standard output layout `<scene>/{sharp,blur,drop,dup,masks,mask_preview}/` 명시 / **§4.5e** SAM 2.1·SAM 3 [13] primary + YOLOv8-seg [14] secondary cross-method check / **§5.5 L7 신규** human-in-the-loop reclassification reproducibility 한계 + audit trail commitment / **§5.6 internal validity** mask source bias + L7 second-order 영향 명시 / **§6.1** C2 preprocess 6-component 정밀 wording. | PAPER_DRAFT §3.2·§4.5e·§5.5·§5.6·§6.1 |
| 2026-05-13 (sharp PNG 통일 정책 — 사용자 사전 처리) | 사용자 video-to-image 모듈이 sharp = JPG, mask = PNG 두 포맷 혼합 출력 → mask 는 PNG 유지, sharp 는 PNG 통일 결정. 변환 자체는 사용자 책임 (사전 처리) 으로 위임 — RUN_PILOT.md 의 변환 ad-hoc 코드 (mogrify / PIL) 는 제거하고 **정책 statement + RAW_FRAMES 적재 후 검증 명령만** 유지. **§3.3 신규 정책 절** — (i) PNG 통일 근거 4가지 (PNG-only glob 호환 / PSNR-SSIM noise floor 정확성 / §3.6 F3 fairness / §4.5d A.3 vs JPEG block artifact 혼동 차단), (ii) RAW_FRAMES 적재 후 leftover_jpg=0 + sharp==mask count 검증 명령. 후속 §3.4–§3.6 번호 유지. | experiments/RUN_PILOT.md §3.3 |
| 2026-05-13 (skip_empty mask 정책 정합) | 사용자 모듈의 `skip_empty` 정책 (dynamic instance 검출 0건 frame mask 미생성 → `len(masks) ≤ len(sharp)`, M ⊆ S) 정합 4 위치 patch — **PAPER §3.2 (d)** skip_empty 명시 + mask on/off condition 정의 정밀화 (mask 없는 frame 은 두 condition 모두 그대로 학습 포함) / **PAPER §4.5e** **full-set comparison 정의** explicit 추가 (S 전체 사용, mask presence frequency |M|/|S| 비율 결과표 부수 column 보고, attenuation bias 는 §5.6 internal validity 로 흡수) / **data/README.md §2·§5** subset 관계 명시 + mask 전체 0개 site 의 §4.5e N/A 처리 / **RUN_PILOT.md §3.3** 검증 명령을 strict equal 강제 → `leftover_jpg=0` + `sharp≥1` + `mask≤sharp` + `orphan_mask=0` 세 조건 완화. | PAPER_DRAFT §3.2·§4.5e / experiments/RUN_PILOT.md·data/README.md |
| 2026-05-13 (sharp/mask 독립 collection 정합) | 사용자 수동 sharp reclassification 로 인한 orphan mask 가능성 확인 (M ⊆ S 가정도 깨짐). 두 폴더를 *독립 collection* 으로 재정의 — 부분집합 / 카운트 강제 모두 제거. 4 위치 wording 정합 patch — **PAPER §3.2 (d)** 두 비대칭 (skip_empty + manual sharp reclassification) 정상 상태 명시 + mask on condition 을 sharp ∩ mask intersection 으로 한정 / **PAPER §4.5e** ablation evidence I = S ∩ M 정의 + orphan mask (M \ S) 자동 제외 + |I|/|S|·|M\S|/|M| 두 비율 결과표 부수 column 보고 / **data/README.md §2·§5** subset wording → 독립 collection / pair 매칭 wording 으로 재작성 / **RUN_PILOT.md §3.3** 검증 명령에서 mask count + orphan_mask 비교 제거 — sharp 측 두 조건 (`leftover_jpg=0` + `sharp≥1`) 만 검증 (mask 는 advisory). | PAPER_DRAFT §3.2·§4.5e / experiments/RUN_PILOT.md·data/README.md |
| 2026-05-18 (hardlink default + multi-server + troubleshooting) | 실제 pilot 환경에서 symlink + docker bind mount 비호환 확인 (host find `-type f` symlink 제외 + container 내부 target prefix 미bind → `n_frames=0` fatal). 4 위치 patch — **reorganize_frames.sh** 에 `--mode hardlink` 추가 + default 를 hardlink 로 변경 + same-FS 사전 검증 (GNU stat `-c '%m'`; BSD/macOS fallback) + idempotent 재실행 보장. **RUN_PILOT.md §3·§3.4** title 및 변환 mode wording 갱신 + mode 선택 가이드표 (hardlink/symlink/rsync/mv × disk × docker 호환) 추가 + m1_colmap image tag `latest` → `3.9.1` 정정 (verify_dockers.sh 와 일치). **RUN_PILOT.md §10 신규** Multi-server setup — docker save/load image distribution (build 1회 후 export → 새 host import) + GPU 점유 변동 manual flag 시나리오 (2 GPU all free / GPU 0 점유 / GPU 1 점유). **RUN_PILOT.md §11 신규** Troubleshooting — symlink+docker 문제 진단/해결 1-shot + `pull access denied` 대응 + `frames/` 상태 진단 4-step 명령. **scripts/README.md** Tier 2 표에 `reorganize_frames.sh` 등재 + hardlink 의 docker 호환성 cross-reference. | experiments/scripts/reorganize_frames.sh·README.md / RUN_PILOT.md §3·§3.4·§10·§11 |
| 2026-05-18 (PIPELINE_FLOW.md 신규) | P1/P9 의 실제 stage flow (run_pipeline_p{1,9}.sh 코드 기준) + P2–P8 의 구현 상태 (deferred) + Tier 3 진입 조건 (pilot 결과-driven) 을 단일 문서로 정식화. **§1** P1/P9 의 의미 (Table 1b 매핑, 사전등록 가설 H-Best/H-Worst 의 두 극단) / **§2** P1 3-stage flow (M1 COLMAP automatic_reconstructor → M8 3DGS train → compute_metrics) docker call 전체 + 산출물 schema / **§3** P9 4-stage flow (M7 MASt3R-SLAM → adapter → M9 2DGS + native TSDF mesh → compute_metrics) / **§4** P2–P8 구현 status table (atomic methods M2–M6 + run_pipeline_p{2..8}.sh 모두 Tier 3 deferred; P2/P8 은 atomic 이미 완비라 30분 작업으로 추가 가능) + 본 단계적 fill 을 PAPER §5.5 L8 후보 항목으로 등재 / **§5** Tier 3 진입 조건 4 시나리오 (H-Best/H-Worst supported 시 P2+P8 우선 / cluster A 강하면 P3+P5 추가 / 전체 supported 시 P4·P6·P7 보강 / refuted 시 진입 보류). | experiments/PIPELINE_FLOW.md (신규) |
| 2026-05-18 (OPENCV → PINHOLE undistort fix) | Pilot 실행 중 P1 Stage 2 에서 `AssertionError: Colmap camera model not handled` 발생 확인 — 3DGS/2DGS upstream `dataset_readers.py` 가 OPENCV camera model 거부 (PINHOLE/SIMPLE_PINHOLE 만 지원). 4 위치 영구 fix — (1) **run_pipeline_p1.sh** 에 **Stage 1.5 (image_undistorter)** 신규 (m1_colmap 컨테이너; idempotent; `--skip-undistort` flag 추가) + Stage 2 `--source_path` 를 `pose/` → `pose_undistorted/` 로 변경 + T_UNDISTORT 를 T_POSE 합산. (2) **run_pipeline_p9.sh** 에 **Stage 2.5 (image_undistorter)** 신규 (m1_colmap 재활용; m7 컨테이너에 colmap binary 부재) + Stage 3 `--source_path` 변경 + T_UNDISTORT 를 T_ADAPT 합산 + M1_IMAGE 변수 추가. (3) **PIPELINE_FLOW.md** P1 도식 3-stage → 4-stage, P9 도식 4-stage → 5-stage 로 갱신 + 각 Stage 1.5/2.5 의 docker call · 산출물 · wall-time 명세 추가. (4) **RUN_PILOT.md §11.2** 신규 troubleshooting — 증상 / 원인 / 영구 fix 명시 + skip-flag 로 이전 stage 건너뛰는 재실행 명령 + idempotent 동작 설명. | experiments/scripts/run_pipeline_p{1,9}.sh · PIPELINE_FLOW.md · RUN_PILOT.md §11 |
| 2026-05-18 (sparse/0 재배치 + docker --user fix) | Pilot 실행 중 두 후속 issue 확인 — (i) `FileNotFoundError: pose_undistorted/sparse/0/images.txt` (COLMAP image_undistorter 가 sparse/ 에 직접 출력 — sparse/0/ 아님 — 3DGS/2DGS 의 sparse/0/ 기대와 mismatch), (ii) sudo 없는 학교 서버에서 root 소유 file 정리 불가 (docker container 가 root 권한으로 산출물 생성). 영구 fix — **run_pipeline_p1.sh / p9.sh** 양쪽에 (1) image_undistorter 직후 sparse → sparse/0 post-process mv 추가 (idempotent check 도 sparse/0/cameras.* 로 갱신) + (2) 모든 docker run (P1 의 3개 + P9 의 5개) 에 `--user "$(id -u):$(id -g)"` 추가 → 신규 file 자동 user 소유로 생성. **RUN_PILOT.md §11.3 신규** troubleshooting — 증상 / 원인 / sudo 우회 ad-hoc (docker container 내부 chown) + 영구 fix 안내. | experiments/scripts/run_pipeline_p{1,9}.sh · RUN_PILOT.md §11 |
| 2026-05-18 (3DGS/2DGS OOM fix — data_device cpu) | Pilot 실행 중 P1 Stage 2 에서 `torch.cuda.OutOfMemoryError` 확인 — 3DGS upstream `--data_device` default 가 `cuda` 라 730 frame × 1920×1080 image 가 GPU 에 모두 적재되어 23 GiB 초과. 단일 4090 (24 GiB) 한계. 영구 fix — **run_pipeline_p1.sh / p9.sh** 의 3DGS · 2DGS train docker call 에 `--data_device cpu` 추가 → image 는 CPU 메모리 적재, batch 단위 GPU 전송. GPU 사용량 ~6 GiB 으로 감소, quality 동일, wall-time +20-30%. **RUN_PILOT.md §11.4 신규** OOM troubleshooting — 증상/원인/영구 fix + ad-hoc docker run 명령. **§3.6 F1 fairness** 변동 없음 (모든 configuration 에 동일 적용). | experiments/scripts/run_pipeline_p{1,9}.sh · RUN_PILOT.md §11.4 |

**rev2 변경 요약:**
- **T1.1** Mechanism cluster 명명: A/C/D → **A/B/C** (B 누락 issue 해소). CHAPTER_PLAN.md sync 완료 (rev2 후속, 별도 entry 참조).
- **T1.2** Sub-cluster ID 명시 (A.1/A.2/A.3, B.1/B.2, C.1/C.2)를 §3.5 본문에 fix.
- **T1.3** "9 baselines" 용어 disambiguation: 9 atomic methods vs N pipeline configurations 구분.
- **T1.4** §3.6 fairness protocol에 industrial/library 영상 길이 정규화 요건 추가.
- **T2.5** §4.4 per-frame bootstrap → **block bootstrap** primary, per-frame은 보조.
- **T2.6** §3.7에 Gaussian primitives → mesh 추출 step 명시.
- **T2.7** §4.6 navigation 실험 부피 감축 옵션 명시 (pilot scaling).
- **T2.8** §4.5에 mask IoU cross-report 요건 추가 (collinearity 검증).

---

## 0. Structure Pattern Selection

**Selected Pattern:** **IMRaD (hybrid)** — Empirical research with original data + systems contribution
- §1 Introduction + §2 Related Work + §3 Pipeline (Method) + §4 Experiments (Results) + §5 Discussion + §6 Conclusion
- KCI 공학 저널 관행에 부합 + thesis(C1+C2 hybrid)와 정합

**Outline Depth Rule (target ≈ 9,000 단어, 8,000–10,000 범위):**
- Level 1 (Chapter): 6개
- Level 2 (Section): 2–4 per chapter (필요 시 7개까지)
- Level 3 (Sub-section): §4.5 ablation에서만 사용

**Each lowest-level heading ≥ 150 words.** (구조상 150 단어 미만이 되면 상위 단계로 병합)

---

## 1. Overview Paragraph

본 논문은 산업현장 보디캠 영상을 입력으로 한 9개 atomic 3D 재구성 방법론 및 그 조합 9 pipeline configurations (P1–P9)의 비교 평가와, 그 결과를 로봇 자율주행(BEV occupancy + IsaacSim + Spot/RRT*)까지 연결한 end-to-end 파이프라인을 제안한다. §1에서 산업현장 도메인 특수성과 기존 벤치마크의 한계로부터 연구 gap을 도출하고, §2에서 9개 atomic method의 계보학적 정리와 산업현장 연구 부재를 부각한다. §3에서 파이프라인 구조·전처리 모듈·도메인 메커니즘 클러스터(A/B/C)·공정성 프로토콜을 제시하고, §4에서 사전 등록 가설(H-Best/H-Worst/H-Gap/H-Mechanism)에 대한 양 도메인 비교 실험과 메커니즘 ablation을 수행한다. §5에서 결과를 문헌과 대화시켜 "도메인-메서드 매칭" 디자인 원칙(C3)을 도출하고, §6에서 결론과 future work를 제시한다.

---

## 2. Detailed Outline

### §1 Introduction (~800 단어)

**Purpose:** 산업현장 robot autonomy를 위한 3D recon의 도메인-특화적 어려움과, 그것이 일반 벤치마크에 가려져 있다는 gap을 설득. Pre-registered claims를 명시하여 사후 cherry-picking 의혹을 차단.

#### 1.1 Background — Industrial Robot Autonomy Demand (~200 단어)
- **Key points:**
  - 스마트팩토리·위험구역 점검·시설관리 자율 로봇 수요 증가
  - LiDAR 의존도가 높지만 비용·setup 제약 → camera-only / body-worn 시나리오의 가치
  - 보디캠은 작업자의 자연스러운 동선을 따라가므로 도메인 영상 수집 비용이 낮음
- **Sources:** *industrial robotics survey papers (pending lit-review)*; smart factory white papers; body-worn camera 활용 사례 [TBD]
- **Evidence type:** Context, market framing

#### 1.2 Problem & Motivation — Why General Benchmarks Are Insufficient (~200 단어)
- **Key points:**
  - ScanNet/Replica/KITTI/Tanks-and-Temples 등은 정돈된 실내·실외 도메인
  - 산업현장은 textureless · reflective · dynamic · low-light가 동시에 작용 (mechanism cluster A/B/C, §3.5 참조)
  - 일반 도메인 SOTA 순위가 산업현장에서도 유지된다는 보장 없음
- **Sources:** ScanNet [Dai17], Replica [Straub19], COLMAP benchmarking 관련 prior work [TBD]
- **Evidence type:** Problem framing, contrast

#### 1.3 Research Gap (~150 단어)
- **Single-sentence gap:**
  > "산업현장 보디캠 영상을 입력으로 9개 최신 3D recon atomic methods(SfM·deep matching·deep SLAM·representation 4계열) 및 그 조합 N pipeline configurations를 일관된 공정성 프로토콜로 비교 평가하고, 그 결과를 로봇 자율주행 task에 연결한 연구는 아직 존재하지 않는다."
- 그 외 sub-gap: ① camera-only industrial recon 부재 ② BEV/IsaacSim까지 이어지는 end-to-end 평가 부재 ③ mechanism causality (textureless·dynamic·photometric)를 분리 검증한 ablation 부재
- **Sources:** §2 entire literature gap analysis
- **Evidence type:** Gap statement

#### 1.4 Contributions and Pre-registered Claims (~200 단어)
- **C1** (β·비교평가): 9-method × 2-domain evaluation
- **C2** (γ·시스템): End-to-end pipeline (capture → preprocess → recon → BEV → IsaacSim → nav)
- **C3** (δ·디자인 원칙): Domain-method matching principle
- **Pre-registered hypotheses (사후 dispute 차단):**
  - H-Best = **MASt3R-SLAM + 2DGS** 가 산업현장에서 가장 우수
  - H-Worst = **COLMAP + 3DGS** 가 가장 열위 (특히 dynamic + low-light)
  - H-Gap = Δ_industrial > Δ_library (p < 0.05)
  - H-Mechanism = cluster A/B/C 각각에서 deep-prior 계열 우위
- **Sources:** INSIGHT 1, INSIGHT 2 (Chapter Plan)
- **Evidence type:** Contribution declaration, falsifiable pre-commitment

#### 1.5 Paper Roadmap (~50 단어)
- §2 Related work → §3 Pipeline design → §4 Experiments → §5 Discussion → §6 Conclusion 한 줄 요약

**Transition to §2:** "다음 절에서는 본 비교에 포함된 9개 atomic methods의 계보학적 정리와 산업현장 도메인 연구 부재를 정리한다."

---

### §2 Related Work (~900 단어)

**Purpose:** 9개 atomic methods을 4개 계열(SfM·learning matching·deep SLAM·representation)으로 구조화하고, 각 계열의 산업현장 적용 사례 부재를 부각하여 §3 method 선택의 합당성을 준비.

#### 2.1 Structure-from-Motion (~150 단어)
- **Key points:**
  - **COLMAP** [Schönberger16] — incremental SIFT-based reconstruction, hand-crafted feature
  - **GLOMAP** [Pan24] — global SfM with rotation/translation averaging, COLMAP 후속
  - 두 방법 모두 textureless / reflective region에서 매칭 실패 → 산업현장 적용 시 fundamental 한계
- **Sources:** [Schönberger16], [Pan24], [Lowe04 SIFT]
- **Evidence type:** Method genealogy

#### 2.2 Learning-based Matching (~150 단어)
- **Key points:**
  - **DUSt3R** [Wang24] — pairwise dense 3D point regression, end-to-end
  - **MASt3R** [Leroy24] — DUSt3R + multi-view matching loss + scale awareness
  - Hand-crafted feature 의존을 우회하지만 표준화된 산업현장 평가는 미흡
- **Sources:** [Wang24], [Leroy24]
- **Evidence type:** Method genealogy + gap

#### 2.3 Deep SLAM (~200 단어)
- **Key points:**
  - **DROID-SLAM** [Teed21] — recurrent BA + dense optical flow, RGB-only
  - **DPV-SLAM** [Lipson24] — patch-graph SLAM, low-memory
  - **MASt3R-SLAM** [Murai25] — MASt3R prior 결합 end-to-end SLAM (sub-thesis core)
  - Deep prior의 강건성은 일반 도메인에서 검증; 산업현장에서의 격차는 미보고
- **Sources:** [Teed21], [Lipson24], [Murai25]
- **Evidence type:** Method genealogy + key thesis support

#### 2.4 3D Representations: 3DGS vs 2DGS (~150 단어)
- **Key points:**
  - **3DGS** [Kerbl23] — anisotropic 3D Gaussians, photorealistic novel-view
  - **2DGS** [Huang24] — 2D oriented disks with surface alignment, planar prior
  - 산업현장의 벽·바닥·기계외관 dominant geometry는 평면적 → 2DGS의 planar prior와 정합 가설
- **Sources:** [Kerbl23], [Huang24], surface reconstruction comparison studies [TBD]
- **Evidence type:** Representation choice rationale

#### 2.5 Industrial / Cluttered Domain Reconstruction (~150 단어)
- **Key points:**
  - 기존 industrial point cloud 연구는 LiDAR 의존 (Heritage scanning, BIM as-built) [TBD]
  - 카메라 기반 industrial site recon은 시도 자체가 드물고, 9-baseline 비교는 부재
  - Construction site monitoring 연구도 mostly LiDAR + ToF 의존
- **Sources:** [Han19 industrial BIM], [Bosché10 construction], comparable LiDAR-based works [TBD]
- **Evidence type:** Domain gap

#### 2.6 Robot Navigation from Reconstructed Maps (~150 단어)
- **Key points:**
  - Mesh / point cloud → occupancy / BEV 변환 prior work [TBD]
  - IsaacSim + Spot + sampling-based planner (RRT*) 연계 사례
  - 그러나 "reconstruction quality가 navigation success rate에 미치는 영향"을 정량 평가한 연구는 부족
- **Sources:** IsaacSim documentation, RRT* original [Karaman11], navigation-from-recon papers [TBD]
- **Evidence type:** End-to-end gap

#### 2.7 Synthesis: What This Paper Adds (~100 단어)
- §2.1–§2.6을 한 단락으로 합쳐 본 논문이 메우는 4-way intersection 강조: (industrial domain) × (camera-only) × (9-method comparison) × (end-to-end navigation evaluation)

**Transition to §3:** "다음 장에서는 본 평가의 전제가 되는 파이프라인 구조와 도메인 메커니즘 분석, 그리고 공정성 프로토콜을 제시한다."

---

### §3 Pipeline Design (~1,400 단어)

**Purpose:** End-to-end pipeline 구조 설명 + 산업현장 도메인의 mechanism cluster 분석 + 9-baseline 평가의 공정성 프로토콜 명세. C2 (시스템) 및 C2-sub-a (preprocessing as α-contribution, Option I-soft) 근거 제시.

#### 3.1 Pipeline Overview (~200 단어)
- **Figure 1:** Pipeline diagram (capture → preprocess → camera mapping → 3D recon → BEV → IsaacSim → navigation)
- 6 stage 각각의 입출력 dtype 명시 (video → filtered frames → camera poses + sparse points → dense 3D rep → BEV occupancy grid → navigation trajectory)
- 본 논문이 변화시키는 stage = camera mapping + 3D rep (9 pipeline configurations P1–P9 비교 대상); 나머지 stage는 고정
- **Sources:** None (original design)
- **Evidence type:** Original system contribution

#### 3.2 Preprocessing Module *(C2-sub-a; α structural contribution)* (~250 단어)
- **Key points:**
  - **FPS filtering** — 입력 보디캠 30fps → 사용자 사양 (e.g., 5–10fps)으로 downsample
  - **Sharpness threshold** — Laplacian variance 기반 blur 프레임 제거
  - **Masking automation** — 작업자 등 dynamic region semantic mask (e.g., SAM2 or YOLO-seg) 자동 생성
  - 모듈은 9 pipeline configurations 모두에 동일하게 적용되어 공정성 보장
- **Algorithm 1:** Preprocessing pseudocode (input video → filtered frame set + masks)
- **Sources:** SAM2 [TBD], YOLOv8-seg [TBD], Laplacian sharpness [Pertuz13]
- **Evidence type:** Module specification + tooling justification

#### 3.3 Camera Mapping Stage (~200 단어)

> **Terminology disambiguation (rev2):** 본 논문은 "9 atomic methods" (각 method가 stage 역할 고정 단위)와 "9 pipeline configurations" (pose × representation 조합 단위)를 구분한다. C1의 "9-method comparison evaluation"은 *9 atomic methods*를 의미하며, end-to-end 비교는 9 pipeline configurations (Table 1b) 단위로 수행. H-Best/H-Worst는 configuration 수준의 사전등록 가설.
>
> **✓ Resolved (rev2):** Option β (pose × representation pipeline configurations) 채택. N = **9** budget-aware subset (full grid 7×2=14 대신). COLMAP·MASt3R-SLAM은 양 representation 모두 평가하여 rep effect 격리 가능; 모든 7 pose method가 ≥1 configuration에 포함. 자세한 enumeration은 Table 1b 참조.

- **Table 1 (atomic methods coverage):** 9 atomic methods × stage 역할 matrix:
  | # | Method | Stage 역할 | 계열 |
  |---|---|---|---|
  | M1 | COLMAP [Schönberger16] | Pose + sparse points | SfM (hand-crafted) |
  | M2 | GLOMAP [Pan24] | Pose + sparse points | SfM (global) |
  | M3 | DUSt3R [Wang24] | Pairwise dense matching | Learning matching |
  | M4 | MASt3R [Leroy24] | Pairwise dense matching | Learning matching |
  | M5 | DROID-SLAM [Teed21] | Pose + depth | Deep SLAM |
  | M6 | DPV-SLAM [Lipson24] | Pose + depth (low-mem) | Deep SLAM |
  | M7 | MASt3R-SLAM [Murai25] | Pose + dense (with prior) | Deep SLAM |
  | M8 | 3DGS [Kerbl23] | Volumetric representation | Representation |
  | M9 | 2DGS [Huang24] | Surface representation | Representation |
- **Table 1b (9 pipeline configurations — fixed in rev2):** End-to-end 비교 단위. 각 configuration ID는 §4.3 Table 2, §4.6 Table 3, §5 본문에서 동일하게 참조.
  | Config | Pose method | Representation | 분류 / 역할 |
  |---|---|---|---|
  | **P1** | M1 COLMAP | M8 3DGS | **H-Worst (사전등록)** — hand-crafted × volumetric |
  | **P2** | M1 COLMAP | M9 2DGS | Hand-crafted × planar (rep cross-ablation vs P1) |
  | **P3** | M2 GLOMAP | M8 3DGS | Global SfM baseline |
  | **P4** | M3 DUSt3R | M8 3DGS | Learning matching × volumetric |
  | **P5** | M4 MASt3R | M9 2DGS | Learning matching × planar |
  | **P6** | M5 DROID-SLAM | M8 3DGS | Deep SLAM × volumetric |
  | **P7** | M6 DPV-SLAM | M9 2DGS | Low-mem deep SLAM × planar |
  | **P8** | M7 MASt3R-SLAM | M8 3DGS | Deep prior × volumetric (rep cross-ablation vs P9) |
  | **P9** | M7 MASt3R-SLAM | M9 2DGS | **H-Best (사전등록)** — deep prior × planar |
- **Design rationale (Table 1b):**
  - **Pose coverage:** 7/7 atomic pose methods 각각 ≥1 configuration에 등장
  - **Representation balance:** 3DGS = 5 configs (P1, P3, P4, P6, P8), 2DGS = 4 configs (P2, P5, P7, P9)
  - **Rep isolation pairs:** P1↔P2 (COLMAP × {3DGS, 2DGS}), P8↔P9 (MASt3R-SLAM × {3DGS, 2DGS}) — §5.3 "Why 2DGS > 3DGS" 분석에 직접 활용
  - **H-Gap 극단 비교:** P1 (H-Worst) vs P9 (H-Best) — §4.4 Δ_industrial 계산의 reference pair
  - **Full 7×2 grid (14)를 14→9로 축소한 이유:** §4.6 navigation run budget 1,080 (9 × 6 × 20)이 이미 한계 — full grid시 1,680 runs로 비현실적
- Pose-only method (M1, M2, M5, M6)는 별도 representation training step 필요 → §3.4와 결합 방식 명시
- **Sources:** §2의 method papers cross-reference
- **Evidence type:** Coverage justification + terminology disambiguation

#### 3.4 3D Representation Stage (~150 단어)
- §3.3 Table 1b의 9 pipeline configurations 중 representation 산출 방식 명세 (예: COLMAP→3DGS, MASt3R-SLAM→2DGS 등)
- 2DGS vs 3DGS 선택 시 hyperparameter 동일 budget (max iter, learning rate, densification interval) 적용
- **Sources:** [Kerbl23], [Huang24]
- **Evidence type:** Representation pairing matrix

#### 3.5 Industrial Domain Characteristics + Mechanism Clusters A/B/C (~300 단어) **★ INSIGHT 3 fully unpacked**

> **Note on naming (rev2):** CHAPTER_PLAN v1의 A/C/D 명명은 본 outline rev2부터 **A/B/C**로 정리한다. B는 CHAPTER_PLAN의 C(Scene Non-staticity), C는 CHAPTER_PLAN의 D(Photometric Drift)에 해당. Sub-cluster ID는 §4.5 ablation 및 §4.1 site 표에서 동일 ID로 참조.

- **Cluster A — Visual Ambiguity:**
  - **A.1 Textureless:** 벽·바닥·콘크리트의 gradient sparsity → feature matching 실패
  - **A.2 Reflective:** 금속 외관에서 view-dependent appearance → multi-view consistency 위반
  - **A.3 오염:** 먼지/페인트 박리로 인한 partial occlusion → noise injection 효과
- **Cluster B — Scene Non-staticity:**
  - **B.1 Dynamic objects:** 작업자, 이동 자재 → pose estimation outlier
  - **B.2 Scale 변동:** 보디캠 근접 촬영(0.5m) ↔ 원거리 통로(20m) 혼재 → depth ambiguity
- **Cluster C — Photometric Drift:**
  - **C.1 Low-light:** 조명 음영 영역
  - **C.2 비균질 조명:** 직사 스포트라이트 + 형광등 mixed → color consistency 위반
- **Sub-cluster ID 정의 표 (operational definitions):**
  | ID | 명칭 | Operational mask 정의 (frame-level) |
  |---|---|---|
  | A.1 | Textureless | Sobel gradient magnitude < τ_tex 영역 |
  | A.2 | Reflective | HSV V-channel saturation peak (specular highlight) |
  | A.3 오염 | Color variance + edge density anomaly (§4.5d 알고리즘) |
  | B.1 | Dynamic | SAM2 / YOLO-seg person+object class mask |
  | B.2 | Scale 변동 | Depth prior median 비율 frame-to-frame > τ_scale |
  | C.1 | Low-light | Mean luminance < τ_lum |
  | C.2 | 비균질 조명 | Luminance variance > τ_var within frame |
- **Figure 2:** Sample frames per sub-cluster (montage) — 산업현장 실제 영상에서 7개 sub-cluster 예시
- **Library control은 A·B·C 모든 cluster에서 약함** → §4 Δ 비교 정당화
- **Sources:** Photometric loss limitations [TBD], dynamic SLAM survey [TBD], textureless feature matching [TBD]
- **Evidence type:** Domain analysis + causal hypothesis

#### 3.6 Fairness Protocol (~150 단어)
- 동일 GPU (RTX 4090 or A6000, 명시)
- 동일 max epoch / iteration budget
- Default hyperparameter (저자 권장값) 사용; 추가 튜닝 없음
- 동일 전처리 모듈 (FPS 동일, 동일 sharpness threshold)
- **영상 길이 정규화 (rev2):** Industrial 5min / Library 1–2min 원본 비대칭을 제거. 두 도메인 모두 동일 *frame budget* (예: N_frames = 1,500 frames, FPS 5 기준 5min) 으로 trim/sample. Library 원본이 짧으면 zero-pad가 아닌 *동일 frame budget 내 dense sampling*; industrial 원본이 길면 등간격 sub-sample. Δ 비교 시 영상 길이가 third variable로 작용하는 것 방지.
- 코드 + 마스크 + hyperparameter config 공개 commitment
- **Sources:** Benchmark fairness best practice [TBD]
- **Evidence type:** Protocol specification

#### 3.7 BEV + IsaacSim Integration *(C2-sub-c)* (~200 단어)
- **Stage 0 — Gaussian → Mesh extraction (rev2):** 3DGS/2DGS는 native mesh를 출력하지 않으므로 별도 추출 단계 필요.
  - **2DGS configurations:** native surface alignment (oriented disks의 normal field) 활용 → TSDF fusion으로 mesh 직접 추출 (Huang24 §3.3 protocol).
  - **3DGS configurations:** 외부 mesh extractor 사용 — **SuGaR** (Guédon24) 또는 **2DGS-extractor** (3DGS → 2DGS-like surface 변환 후 fusion). 본 논문에서는 *동일 extractor (SuGaR default config)* 를 모든 3DGS configuration에 적용하여 공정성 보장.
  - Pose-only methods의 sparse point cloud는 Poisson surface reconstruction (default depth=9) 적용 후 mesh 추출.
- **Stage 1 — BEV occupancy grid construction (Algorithm 2):** Mesh → orthographic top-down projection + height threshold (z ∈ [0.1m, 2.0m]) + 2D voxelization (cell size = 0.05m).
- **Stage 2 — IsaacSim import workflow:** Mesh → USD format (USDA + USDC) → Spot robot scene placement → physics enable.
- **Stage 3 — Navigation harness:** RRT* with bounded search radius, start/goal pair sampling per scene (§4.6 protocol).
- **Sources:** IsaacSim docs, RRT* [Karaman11], SuGaR [Guédon24 TBD], Poisson surface reconstruction [Kazhdan06 TBD], 2DGS native surface [Huang24].
- **Evidence type:** Integration specification + extractor fairness

**Transition to §4:** "다음 장에서는 §3에서 정의된 공정성 프로토콜 하에서 9 pipeline configurations × 2 domain 비교 평가와 메커니즘 ablation을 수행한 결과를 보고한다."

---

### §4 Experiments (~1,700 단어)

**Purpose:** 사전 등록 가설 (H-Best, H-Worst, H-Gap, H-Mechanism)을 실증 검증 + ablation으로 mechanism causality 입증.

#### 4.1 Datasets (~150 단어)
- **Industrial:** 3 site × 5min body-worn videos (총 ~15min). Site 특성표:
  | Site | 특성 dominant | A/B/C sub-cluster 강도 (high) |
  |---|---|---|
  | I-1 | 생산라인 (금속 + 작업자 동선) | A.2, A.3, B.1 |
  | I-2 | 외부 점검 통로 (콘크리트 + 저조도) | A.1, A.3, C.1, C.2 |
  | I-3 | 기계실 (반사재질 + 좁은 공간) | A.2, A.3, B.2 |
- **Library control:** 3 site × 영상 길이 fairness 정규화 후 산업현장과 동일 frame budget로 trim (§3.6 참조; relatively static + good lighting + textured shelves)
- **Sources:** None (original dataset)
- **Evidence type:** Original data

#### 4.2 Metrics (~200 단어)
- **Reconstruction quality:**
  - PSNR / SSIM / LPIPS (novel-view synthesis on held-out frames)
  - Chamfer Distance (mesh-to-mesh, with library control as low-bar reference)
- **Robot navigation suitability:**
  - BEV occupancy IoU (vs manual annotation)
  - RRT* success rate (over 20 random start/goal pairs per scene)
  - Average path length, collision count
- **Efficiency:**
  - GPU memory peak
  - Wall-clock time per scene
- 각 metric마다 higher/lower-is-better 명시
- **Sources:** PSNR/SSIM/LPIPS standard refs, Chamfer Distance refs, IoU standard
- **Evidence type:** Metric specification

#### 4.3 Main Result — 9 Pipeline Configurations × 2 Domain Comparison (~300 단어)
- **Table 2:** 9 pipeline configurations (P1–P9, §3.3 Table 1b) × {Industrial, Library} × {PSNR, SSIM, LPIPS, Chamfer, BEV IoU, Nav success, mem, time}.
- **Figure 3:** Bar chart per metric per domain (with error bars). Bar group이 configuration ID (P1–P9).
- §1.4의 H-Best (M7 MASt3R-SLAM + M9 2DGS) 와 H-Worst (M1 COLMAP + M8 3DGS) 사전 명시값 vs 실측값 비교
- 각 cell에 "expected (사전 등록) → observed"를 병기하여 falsification 명확성 확보
- 차원 축소가 필요할 경우 일부 metric (mem, time)은 Appendix B로 이관 — 본문 Table 2는 quality + nav 중심
- **Sources:** [Schönberger16, Pan24, Wang24, Leroy24, Teed21, Lipson24, Murai25, Kerbl23, Huang24]
- **Evidence type:** Primary empirical result

#### 4.4 H-Gap Statistical Test (~200 단어)
- Δ_industrial = (Best industrial score) − (Worst industrial score)
- Δ_library = (Best library score) − (Worst library score)
- **Test (rev2 — block-aware):**
  - **Primary:** *Moving-block paired bootstrap* (block length L ≈ √N_frames, 권장 L = 30 frames @ 5 FPS; 1,000 resamples). Frame 간 temporal correlation을 block 단위로 보존하여 독립성 가정 위반 회피. **Künsch (1989)** moving-block bootstrap convention [LIT_REVIEW ref 26]. *(주의: 출처는 Politis & Romano 1994 아님 — 동 논문은 별개의 Stationary Bootstrap [LIT_REVIEW ref 27])*
  - **Secondary:** Site-level paired test (n=3 industrial vs n=3 library; non-parametric Wilcoxon signed-rank). Site를 i.i.d. 단위로 보는 conservative test.
  - **Tertiary (보조):** Per-frame naive paired bootstrap — 독립성 위반 인지 하에 *상한 효과 크기 추정용*으로만 보고. 본문에서는 primary 결과를 인용.
- **Output:** Δ_industrial − Δ_library 의 95% CI (block bootstrap), p-value (Wilcoxon). 세 가지 test 결과를 Appendix에 병기.
- **Figure 4:** Effect size forest plot (per metric, primary block bootstrap CI).
- **Sources:** Künsch (1989) [LR-26] moving-block bootstrap (primary); Politis & Romano (1994) [LR-27] stationary bootstrap (sensitivity, secondary); Wilcoxon signed-rank standard ref.
- **Evidence type:** H-Gap falsification + statistical robustness

#### 4.5 Mechanism Ablation **(★ 가장 risky; 강화 설계)**

##### 4.5a Stage 0 — Pilot Study (~100 단어)
- 1 site × 2 method (COLMAP, MASt3R-SLAM) × textureless mask on/off
- Effect size > 0.2 (Cohen's d) 미만 시 §4.5b–d redesign
- **Sources:** Cohen effect size convention
- **Evidence type:** Internal validity check

##### 4.5b Textureless Region Ablation (~120 단어) — Cluster A.1
- **방법:** Gradient magnitude < threshold 영역을 mask로 정의, 해당 영역의 frame fraction 변화 → recon quality 변화 측정
- Method × {full, masked-out, masked-in only} matrix
- **Figure 5a:** Quality vs textureless fraction 곡선 (per method)
- **Sources:** Sobel gradient feature density refs
- **Evidence type:** Cluster A.1 causality

##### 4.5c Reflective Region Ablation (~120 단어) — Cluster A.2
- **방법:** Specular highlight detection (HSV V-channel saturation peak 검출) 기반 마스킹
- 동일 method × mask matrix 적용
- **Figure 5b:** Quality vs reflective fraction
- **Sources:** Specular detection refs
- **Evidence type:** Cluster A.2 causality

##### 4.5d 오염 Region Ablation (~120 단어) — Cluster A.3
- **방법:** Color variance + edge density 기반 오염 영역 segmentation
- **Figure 5c:** Quality vs 오염 fraction
- (※ 세 ablation을 redundant하게 수행하는 이유: Cluster A causality를 multi-evidence로 강화)
- **Sources:** Anomaly segmentation refs
- **Evidence type:** Cluster A.3 causality

##### 4.5d-aux Mask Cross-Report (rev2) (~80 단어) — Redundancy vs Collinearity 검증
- **Table 5:** §4.5b/c/d 의 3개 sub-cluster mask (A.1 textureless / A.2 reflective / A.3 오염) 간 *pairwise IoU* 보고. Per-site 평균 + global 평균.
- **해석 기준:**
  - 평균 IoU < 0.2 → 세 mask는 거의 disjoint → 세 ablation은 *independent evidence* (redundancy by design 성공).
  - 평균 IoU > 0.5 → mask가 collinear → ablation effect가 분리 불가능 → §5.5 limitations에 명시.
- **Evidence type:** Internal validity check (mask 분리도)

##### 4.5e Dynamic Object Removal Ablation (~100 단어) — Cluster B.1
- **방법:** SAM2/YOLO-seg 마스크 적용/미적용 ablation
- 작업자 mask % 변화에 따른 pose estimation drift 측정
- **Figure 6:** Trajectory drift vs dynamic object fraction
- **Sources:** [SAM2 TBD], [YOLOv8 TBD]
- **Evidence type:** Cluster B.1 causality

##### 4.5f Low-light / Photometric Drift Ablation (~100 단어) — Cluster C
- **방법:** Gamma 보정 적용/미적용 ablation; 또는 histogram equalization (C.1 mask) + luminance variance normalization (C.2 mask) 별도 보고
- **Figure 7:** Quality vs mean luminance (C.1) + Quality vs luminance variance (C.2)
- **Sources:** Photometric augmentation refs
- **Evidence type:** Cluster C causality

#### 4.6 Robot Navigation Evaluation (IsaacSim + Spot + RRT*) (~250 단어)
- 9 pipeline configurations (P1–P9) × 6 scenes (3 industrial + 3 library) × K start/goal pairs × RRT* navigation
- **Run budget 계산 (rev2):** Default K=20 시 9 × 6 × 20 = **1,080 runs**. 1 run 평균 2분 가정 시 **~36시간** wall-clock.
- **부피 감축 옵션:**
  - **Option A (full):** K=20, 모든 N × 6 scene 평가. IsaacSim batch parallelization (≥4 GPU) 권장.
  - **Option B (tiered):** Pilot K=5 → 결과 분포 보고 → outlier configuration에 한해 K=20 확장. Sample-efficient.
  - **Option C (subset):** Industrial 3 scene 전체 + Library 1 scene 대표만, K=20. Library는 baseline reference로 축소.
  - 본 논문 기본 채택: **Option B**, 단 H-Best/H-Worst configuration은 Option A 수준으로 K=20 보장 (pre-registration 충실성).
- **Table 3:** Configuration × {success rate, avg path length, collision count, planning time}
- **Figure 8:** Representative navigation trajectories (H-Best vs H-Worst side-by-side)
- Reconstruction quality (BEV IoU) vs Navigation success rate scatter plot → Pearson r, Spearman ρ 보고 (configuration 단위 n=9).
- **Sources:** IsaacSim, RRT* [Karaman11], IsaacSim parallel sim API [TBD]
- **Evidence type:** End-to-end suitability + sample-efficient design

**Transition to §5:** "다음 장에서는 위 결과를 §2의 문헌과 대화시키고, 도메인-메서드 매칭 디자인 원칙(C3)을 도출한다."

---

### §5 Discussion (~1,100 단어)

**Purpose:** §4 결과를 literature와 dialogue + C3 design principle 도출 + limitations 정직 공개.

#### 5.1 H 검증 결과 요약 (~200 단어)
- **Table 4:** H-Best / H-Worst / H-Gap / H-Mechanism 별 {supported, partial, refuted, inconclusive}
- 사전 등록 vs 실측 결과 차이가 있다면 정직하게 보고 + 가능한 원인 후보 1–2개
- **Sources:** §1.4 pre-registration
- **Evidence type:** Hypothesis verdict

#### 5.2 Why Deep Prior > Hand-crafted in Industrial Domain (~250 단어)
- Cluster A (textureless·reflective·오염) — hand-crafted SIFT는 keypoint repeatability 붕괴; deep matching은 dense correspondence regression이라 sparse keypoint 의존성이 없음
- Cluster B (dynamic·scale) — deep SLAM은 학습 데이터에 dynamic 시나리오 포함; classical SfM은 가정 위반 시 catastrophic failure
- Cluster C (photometric) — deep network는 photometric variance에 견디는 표현 학습 (data augmentation 영향)
- 단, deep method도 OOD (out-of-distribution) 산업현장에서는 limitations 존재 — §5.5에서 후술
- **Sources:** §2.2–§2.3 cross-reference, robustness analysis refs [TBD]
- **Evidence type:** Mechanism explanation

#### 5.3 Why 2DGS > 3DGS in Industrial Domain (~200 단어)
- 산업현장 dominant geometry = planar (벽·바닥·기계 외관) → 2DGS의 surface-aligned disk가 정합
- 3DGS는 anisotropic Gaussian으로 표현력 높으나 sparse view + planar dominant 환경에서 over-parameterized
- BEV 변환 시 2DGS의 surface alignment는 occupancy grid 추출에 직접 도움 (height threshold 노이즈 감소)
- **Sources:** [Kerbl23], [Huang24], surface alignment analysis [TBD]
- **Evidence type:** Representation-domain match argument

#### 5.4 Design Principle (C3) — Domain-Method Matching (~150 단어)
- **Principle statement (Box):**
  > "Industrial camera-only 3D recon for robot autonomy: prefer deep-prior pose estimation (e.g., MASt3R-SLAM, DPV-SLAM) + planar-prior representation (e.g., 2DGS). Hand-crafted SfM + isotropic 3D representation is not recommended for body-worn industrial inputs."
- 도메인 mechanism 식별 → 해당 mechanism에 견디는 prior 선택 → 일반 벤치마크 순위보다 더 신뢰할만한 기준
- **Sources:** 본 논문 §4 results
- **Evidence type:** Actionable design principle

#### 5.5 Limitations (~200 단어)
- **n=3 sites** — 일반화 한계, 통계 power 한계 (mitigation: per-frame bootstrap, future work 확장)
- **단일 보디캠** — multi-cam fusion 미포함
- **Weather / season 미반영** — 외부 통로의 우천·결로 등 미평가
- **Single GPU 환경** — 분산 학습 시 결과 차이 가능성
- **Hyperparameter default 사용** — 각 method의 best-tuned 성능은 미평가 (의도된 공정성 trade-off)
- **Real-world deployment 미검증** — IsaacSim sim-to-real gap
- **Sources:** None (self-report)
- **Evidence type:** Honest limitations

#### 5.6 Threats to Validity (~150 단어)
- **Framework:** Wohlin et al. (2012) [LR-28] 4-threat 분류(Internal / External / Construct / Conclusion) 기반.
- **Internal:** Mask 생성 알고리즘의 ground-truth 없음 → inter-method 일관성으로 부분 보완.
- **External:** 3 site는 산업현장 전체를 대표하지 못함 → outdoor + heavy equipment site 향후 확장. Case study 외부타당도 한계는 Runeson & Höst (2009) [LR-29] 가이드라인 절차에 따라 명시.
- **Construct:** "Navigation suitability"를 RRT* success rate로 측정 — 다른 planner (PRM, A* on BEV) 결과는 다를 수 있음.
- **Conclusion (Statistical):** n=3에서 paired bootstrap의 robust 한계 — block bootstrap + Wilcoxon site-level 이중 검정으로 부분 보완 (§4.4).
- **Sources:** Wohlin et al. (2012) [LR-28] primary + Runeson & Höst (2009) [LR-29] case study secondary.
- **Evidence type:** Methodological self-critique

**Transition to §6:** "마지막 장에서 가장 중요한 발견과 향후 연구 방향을 정리한다."

---

### §6 Conclusion (~250 단어)

**Purpose:** 한 단락 압축 메시지 + future work.

#### 6.1 Summary (~150 단어)
- Restate gap (1 문장)
- 핵심 contribution C1+C2+C3 한 줄씩
- 가장 중요한 finding: H-Gap 결과 한 줄 (e.g., "Δ_industrial이 Δ_library 대비 X.X배 크며, 그 격차는 cluster A mechanism으로 설명된다")
- C3 design principle 재강조 (한 문장)

#### 6.2 Future Work (~100 단어)
- Outdoor industrial sites (건설현장·플랜트) 확장
- Multi-modal fusion (camera + IMU + opportunistic LiDAR)
- On-device real-time deployment 검증
- Long-term temporal consistency (월 단위 site change tracking)
- Multi-robot collaborative mapping

**Sources:** None (forward-looking)
**Evidence type:** Conclusion + outlook

---

### Front/Back Matter

- **Abstract (KR + EN bilingual, ~250 단어 각)** — `/ars-abstract` 단계에서 생성
- **Keywords (5–7 per language)** — e.g., 3D reconstruction, industrial robotics, body camera, SLAM, Gaussian splatting, robot navigation, KCI
- **References (~600–800 단어 분량)** — IEEE 형식, 30–50 ref 예상
- **Appendix (optional):**
  - A. Preprocessing module hyperparameters
  - B. 9 pipeline configurations (P1–P9) 실행 config + 9 atomic methods 개별 hyperparameter
  - C. Ablation mask 생성 algorithm pseudocode
  - D. IsaacSim scene configuration

---

## 3. Word Count Summary

| Section | % | Target Words | Status |
|---|---|---|---|
| §1 Introduction | 13% | ~800 | OK |
| §2 Related Work | 14% | ~900 | OK |
| §3 Pipeline Design | 23% | ~1,450 | rev2: §3.7 +50 (mesh 추출) |
| §4 Experiments | 28% | ~1,780 | rev2: §4.4 +30, §4.5d-aux +80, §4.6 +30 (Alg 3, Tab 5 추가) |
| §5 Discussion | 18% | ~1,100 | OK |
| §6 Conclusion | 4% | ~250 | OK |
| **본문 소계** | **100%** | **~6,340** | rev2 +190 (8 fix 반영) |
| Abstract (KR+EN) | — | ~500 | fixed |
| References | — | ~600–800 | fixed |
| Appendix (optional) | — | ~500 | optional |
| **총합** | | **~8,000–10,000** | KCI 공학 8–12 page 적합 |

**Sum deviation:** 본문 6,150 / 총합 8,000~10,000 = ±5% 이내 ✓

---

## 4. Evidence Map (Source → Section Assignment)

> `/ars-lit-review` 실행 완료 (2026-05-11). 정식 annotated bibliography → [LIT_REVIEW.md](LIT_REVIEW.md) 참조. [TBD] 7/8개 해소 완료.

| Source | IEEE ref (LR#) | Assigned Section(s) | Stance | Status |
|---|---|---|---|---|
| Schönberger16 (COLMAP) | [1] | §1.2, §2.1, §3.3, §4.3 | Neutral baseline | ✅ CVPR 2016 |
| Pan24 (GLOMAP) | [2] | §2.1, §3.3, §4.3 | Neutral baseline | ✅ ECCV 2024 |
| Wang24 (DUSt3R) | [3] | §2.2, §3.3, §4.3 | Supports thesis | ✅ CVPR 2024 |
| Leroy24 (MASt3R) | [4] | §2.2, §3.3, §4.3 | Supports thesis | ✅ ECCV 2024 |
| Teed21 (DROID-SLAM) | [5] | §2.3, §3.3, §4.3 | Supports thesis | ✅ NeurIPS 2021 |
| Lipson24 (DPV-SLAM) | [6] | §2.3, §3.3, §4.3 | Supports thesis | ✅ ECCV 2024 |
| Murai25 (MASt3R-SLAM) | [7] | §2.3, §3.3, §4.3, §5.2 | **Strongly supports** | ✅ CVPR 2025 |
| Kerbl23 (3DGS) | [8] | §2.4, §3.3, §4.3 | Neutral baseline | ✅ SIGGRAPH 2023 |
| Huang24 (2DGS) | [9] | §2.4, §3.3, §4.3, §5.3 | **Strongly supports** | ✅ SIGGRAPH 2024 |
| Lowe04 (SIFT) | [10] | §2.1 | Background | ✅ IJCV 2004 |
| Dai17 (ScanNet) | [11] | §1.2 | Contrast | ✅ CVPR 2017 |
| Straub19 (Replica) | [12] | §1.2 | Contrast | ✅ arXiv 2019 |
| Ravi24 (SAM2) | [13] | §3.2, §4.5e | Tool reference | ✅ arXiv 2408.00714 |
| Jocher23 (YOLOv8) | [14] | §3.2, §4.5e | Tool reference | ✅ GitHub 2023 |
| Pertuz13 (sharpness) | [15] | §3.2 | Tool reference | ✅ Pattern Recog. 2013 |
| Kazhdan06 (Poisson recon) | [16] | §3.7 | Tool reference | ✅ SGP 2006 |
| Guédon24 (SuGaR) | [17] | §3.7 | Tool reference | ✅ CVPR 2024 |
| Karaman11 (RRT*) | [18] | §3.7, §4.6 | Tool reference | ✅ IJRR 2011 |
| Bosché10 (industrial BIM) | [19] | §2.5 | Gap evidence | ✅ Adv. Eng. Inf. 2010 |
| Xue21 (image-based review) | [20] | §2.5 | Gap evidence (review) | ✅ Applied Sciences 2021 (CrossRef+OpenAlex 2026-05-11) |
| Sun25 (surveillance cam recon) | [21] | §2.5 | Gap evidence (recent) | ✅ Buildings 2025 (CrossRef+OpenAlex 2026-05-11) |
| IsaacSim docs | — | §3.7, §4.6 | Tool reference | — (공식 문서) |
| Verbin22 (Ref-NeRF) | [22] | §3.5, §5.2 | Supports Cluster A.2/C | ✅ CVPR 2022 |
| Bescos18 (DynaSLAM) | [23] | §3.5, §5.2 | Supports Cluster B | ✅ RA-L 2018 |
| Romanoni19 (TAPA-MVS) | [24] | §3.5, §5.2 | Supports Cluster A.1 | ✅ ICCV 2019 |
| Bergmann19 (MVTec AD) | [25] | §3.5, §4.5d | Supports Cluster A.3 | ✅ CVPR 2019 |
| Künsch89 (block bootstrap) | [26] | §4.4 | Statistical primary | ✅ Ann. Stat. 1989 |
| Politis94 (stationary bootstrap) | [27] | §4.4 | Statistical secondary | ✅ JASA 1994 |
| Wohlin12 (Experimentation in SE) | [28] | §5.6 | Validity framework primary | ✅ Springer 2nd ed. 2012 |
| Runeson09 (case study guidelines) | [29] | §5.6 | Case study external validity | ✅ Empirical SE 2009 |
| Cohen effect size | — | §4.5a | Methods convention | — (standard) |

**[TBD] 해소 현황:** 8개 카테고리 **전부 완료**:
- ✅ Industrial BIM [19][20][21] / Photometric loss [22] / Dynamic SLAM [23] / Textureless matching [24] / Specular detection [22] / Anomaly segmentation [25] / Bootstrap stats [26][27] / Validity framework [28][29]

---

## 5. Figure / Table / Algorithm Inventory

| # | Type | Title | Section | Note |
|---|---|---|---|---|
| Fig 1 | Diagram | Pipeline overview (6 stage) | §3.1 | Original |
| Fig 2 | Image | Sample frames per mechanism cluster (A/B/C, 7 sub-cluster montage) | §3.5 | Original |
| Fig 3 | Bar chart | 9-baseline × 2-domain × metric | §4.3 | with error bars |
| Fig 4 | Forest plot | H-Gap effect size per metric | §4.4 | |
| Fig 5a | Curve | Quality vs textureless fraction | §4.5b | |
| Fig 5b | Curve | Quality vs reflective fraction | §4.5c | |
| Fig 5c | Curve | Quality vs 오염 fraction | §4.5d | |
| Fig 6 | Curve | Trajectory drift vs dynamic fraction | §4.5e | |
| Fig 7 | Curve | Quality vs mean luminance | §4.5f | |
| Fig 8 | Trajectory | RRT* nav (best vs worst recon, side-by-side) | §4.6 | |
| Tab 1 | Matrix | 9-baseline coverage (4 categories) | §3.3 | |
| Tab 2 | Result | 9-baseline × 2-domain × metric (main result) | §4.3 | |
| Tab 3 | Result | Navigation evaluation per method | §4.6 | |
| Tab 4 | Verdict | H-Best/Worst/Gap/Mechanism verdict | §5.1 | |
| Tab 5 | Matrix | Sub-cluster mask pairwise IoU (A.1/A.2/A.3) | §4.5d-aux | rev2 추가 |
| Alg 1 | Pseudocode | Preprocessing module | §3.2 | |
| Alg 2 | Pseudocode | BEV occupancy grid construction | §3.7 | |
| Alg 3 | Pseudocode | Gaussian → mesh extraction (2DGS native / 3DGS SuGaR) | §3.7 | rev2 추가 |

**Color palette:** Colorblind-safe (Okabe-Ito), APA 7.0 figure formatting (per ARS visualization standard).

---

## 6. Transition Logic Cross-Check

| Boundary | Transition |
|---|---|
| §1 → §2 | "이제 9 atomic methods의 계보학적 정리와 산업현장 연구 부재를 살펴본다" |
| §2 → §3 | "본 비교의 전제가 되는 파이프라인 구조·메커니즘 분석·공정성 프로토콜을 정의한다" |
| §3 → §4 | "위 프로토콜 하에서 9 pipeline configurations × 2 domain 실험과 mechanism ablation을 수행한 결과를 보고한다" |
| §4 → §5 | "결과를 §2 문헌과 dialogue시켜 디자인 원칙을 도출한다" |
| §5 → §6 | "마지막으로 가장 중요한 발견과 future work를 정리한다" |

---

## 7. Quality Gate Checklist (Phase 2 완료 조건)

- [x] 6 IMRaD hybrid 구조 사용
- [x] 모든 section에 Purpose 명시
- [x] Word count sum 본문 ~6,340 / 총 ~9,200 (±5% 이내, rev2 반영)
- [x] 모든 candidate source가 ≥1 section에 할당됨
- [x] 인접 section 간 transition logic 명시
- [x] Heading depth Level 1–3 only (APA convention 준수)
- [x] **Tier 1+2 audit fix 반영 (rev2, 2026-05-11)** — 8개 fix 모두 patch log 등록
- [x] **CHAPTER_PLAN.md sync** — cluster A/C/D → A/B/C 동기화 완료 (2026-05-11 rev2)
- [x] **§3.3 Option β 확정** — N=9 pipeline configurations (P1–P9, Table 1b) 확정 (2026-05-11 rev2)
- [x] **User approval (rev2)** — 2026-05-11 승인 완료. Outline 단계 종료, downstream (lit-review / 실험 / 본문) 진입 가능.

---

## 8. Next-Step Roadmap

```
[현재] PAPER_OUTLINE.md 완료 ✓
   │
   ├─→ User review & approval (next checkpoint)
   │
   ├─→ /ars-lit-review (Evidence Map의 [TBD] 8개 카테고리 보강)
   │      └─→ Annotated bibliography 산출 → Evidence Map 갱신
   │
   ├─→ 실험 단계 (9 pipeline configurations × 2 domain 실행, §4 데이터 산출)
   │
   ├─→ /ars-full 또는 수동 본문 작성 (§3, §4, §5 순)
   │
   └─→ /ars-abstract (KR+EN bilingual abstract, 본문 확정 후)
```

**현재 권장 경로:**
- **즉시:** outline 승인 + `/ars-lit-review` 실행하여 Evidence Map 완성
- **병렬:** 실험 환경 셋업 (9 atomic methods 도커화, 데이터셋 정리)
- **이후:** 결과 산출 → 본문 작성 → bilingual abstract → 인용/포맷 검증
