# Annotated Bibliography + §2 Related Work Draft

> ARS `academic-paper` `lit-review` mode 산출물
> 생성일: 2026-05-11
> Upstream: [PAPER_OUTLINE.md](PAPER_OUTLINE.md) (outline rev2)
> Oversight: **Medium** / Spectrum: **Fidelity**
> 인용 형식: IEEE

---

## 수정 알림 (outline rev2 → lit-review 단계)

| 항목 | 내용 |
|---|---|
| **[필수 수정] §4.4 bootstrap 귀속 오류** | outline §4.4는 "Politis & Romano (1994) moving-block bootstrap"으로 기재했으나, 이동-블록 부트스트랩의 원 출처는 **Künsch (1989)** 이다. Politis & Romano (1994)는 별개의 "Stationary Bootstrap"(무작위 블록 길이). PAPER_OUTLINE.md §4.4 수정 필요. |
| GLOMAP venue | ECCV 2024 확정 (arXiv:2407.20219). 기존 "Pan24" 레이블 유지. |
| DPV-SLAM venue | ECCV 2024 확정 (arXiv:2408.01654). |
| MASt3R venue | ECCV 2024 확정 (arXiv:2406.09756). |
| MASt3R-SLAM venue | CVPR 2025 확정 (arXiv:2412.12392). |
| SuGaR venue | CVPR 2024 확정 (arXiv:2311.12775). |

---

## 1. §2 Related Work 초안 (~900 단어, 한국어 본문)

### §2.1 Structure-from-Motion

Structure-from-Motion(SfM)은 다시점 이미지로부터 카메라 자세와 희소 3D 점군을 동시에 추정하는 핵심 파이프라인으로, COLMAP[1]이 사실상 표준으로 자리잡고 있다. COLMAP은 SIFT[10] 특징점 기반의 점진적(incremental) 재구성 전략을 채택하여 넓은 범위의 데이터셋에서 안정적인 성능을 보인다. 그러나 SIFT를 비롯한 hand-crafted 특징 검출기는 gradient sparsity가 낮은 무질감(textureless) 영역이나 금속 반사면과 같이 viewpoint에 의존적인 외관을 가진 영역에서 keypoint repeatability가 붕괴되는 근본적 한계를 지닌다[24]. GLOMAP[2]은 전역(global) SfM 방식으로 회전·이동 평균화(rotation and translation averaging)를 병렬 처리하여 COLMAP 대비 수십 배 빠른 속도를 달성하면서도 정밀도를 유지하지만, hand-crafted 특징점 의존성은 동일하게 유지된다. 두 방법 모두 산업현장과 같이 textureless, reflective, 오염 표면이 공존하는 환경에서 체계적인 성능 검증이 이루어진 사례는 거의 없다.

### §2.2 Learning-based Matching

DUSt3R[3]는 두 이미지 간 대응 관계를 희소 keypoint 없이 dense 3D pointmap regression으로 직접 추정함으로써 hand-crafted 특징점 의존성을 우회한다. Transformer 인코더-디코더 구조를 활용하여 카메라 내외부 파라미터 없이도 두 이미지의 공통 3D 구조를 단일 순전파(forward pass)로 추정할 수 있다. MASt3R[4]는 DUSt3R를 다시점(multi-view) 및 스케일 인식(scale-aware) 매칭으로 확장하여 장거리 대응 정확도를 개선한다. 두 방법 모두 textureless 및 저조도 환경에서 일반 도메인 벤치마크 대비 우수한 성능을 시연하였으나, 산업현장 도메인에서의 강건성 검증 데이터는 부재하다.

### §2.3 Deep SLAM

Deep Visual SLAM 계열은 학습 기반 특징 및 재귀적 최적화를 활용하여 동적 환경과 저조도 조건에서 고전적 SfM 대비 강건성을 높인다. DROID-SLAM[5]은 Dense Optical Flow 기반 재귀적 Bundle Adjustment(BA)를 통해 단안(monocular), 스테레오, RGB-D 카메라를 통합 지원하며 동적 시나리오가 포함된 학습 데이터 덕분에 Cluster B(동적 물체) 조건에서 SfM보다 우수한 강건성을 보인다. DPV-SLAM[6]은 patch-graph SLAM 구조로 DROID-SLAM 대비 2.5배 빠른 속도와 현저히 낮은 GPU 메모리(5–7 GB)를 달성하며 실시간 처리에 적합하다. MASt3R-SLAM[7]은 MASt3R의 3D 재구성 prior를 SLAM에 통합하여 카메라 모델 가정 없이 15 FPS의 실시간 밀집 재구성(dense reconstruction)을 수행하며, 본 논문에서 H-Best(P9) 파이프라인의 pose estimation 구성 요소로 사전 등록되어 있다. 단, 세 방법 모두 산업현장의 textureless·reflective 환경(Cluster A)에서의 성능은 공개 데이터셋에서 체계적으로 보고된 바 없다.

### §2.4 3D 표현: 3DGS vs. 2DGS

3D Gaussian Splatting(3DGS)[8]은 이방성 3D Gaussian 기본 요소(primitive)를 이용한 rasterization 기반 novel-view synthesis 방법으로, NeRF 대비 수십 배 빠른 렌더링 속도를 달성하면서도 높은 사진 현실성을 유지한다. 그러나 3DGS는 isotropic 혹은 부정형의 볼류메트릭 표현을 사용하므로, 표면 정렬 형상 추출이 어렵고 sparse view 환경에서 over-parameterized 경향이 있다. 2D Gaussian Splatting(2DGS)[9]은 3D Gaussian 대신 표면 정렬된 2D disk를 기본 요소로 사용하여 planar prior를 부여하며, 이로 인해 표면 재구성의 기하학적 정확도가 개선된다. 산업현장의 dominant geometry는 벽·바닥·기계 외관 등 평면적 구조가 높은 비율을 차지하므로, 2DGS의 planar prior가 3DGS보다 본 도메인과 정합성이 높다는 것이 본 논문의 핵심 가설(H-Best, §5.3)이다.

### §2.5 산업현장 / 클러터드 도메인 3D 재구성

산업현장의 3D 재구성 선행 연구는 대부분 LiDAR 또는 구조광(structured light) 기반이다. Bosché[19]는 레이저 스캐닝 점군에서 CAD 모델 객체를 자동 인식하는 Scan-vs-BIM 프레임워크를 제안하였으며, 건설현장 시공 진도 관리에 활용되었다. 이미지 기반 건설 진도 모니터링 측면에서 Xue 등[20]은 photogrammetry·SfM·MVS 등 image-based 3D reconstruction 방법론을 체계적으로 종합하였고, 보다 최근 Sun 등[21]은 고정 감시 카메라 영상으로부터 준-실시간(near real-time) 3D 재구성 파이프라인을 제안하였다. 그러나 두 연구의 대상 카메라는 대부분 고정 감시 카메라 또는 UAV이며 보디캠(body-worn camera) 시나리오 및 동적 환경 강건성은 다루지 않는다. 카메라 전용(camera-only) 산업현장 재구성은 비용·설치 제약이 있는 LiDAR를 대체할 수 있는 유망한 방향임에도 불구하고, 최신 신경 3D 표현(3DGS/2DGS, deep SLAM)과의 체계적 비교 연구는 결여되어 있다.

### §2.6 재구성 지도 기반 로봇 내비게이션

로봇 자율주행을 위한 경로 계획 알고리즘으로는 Karaman & Frazzoli[18]가 제안한 RRT*(Rapidly-exploring Random Tree Star)가 점근적 최적성(asymptotic optimality)을 보장하는 샘플링 기반 방법으로 널리 사용된다. 3D 재구성 결과로부터 BEV(Bird's Eye View) occupancy 맵을 생성하여 경로 계획에 활용하는 사례는 증가하고 있으나, **재구성 품질(PSNR, Chamfer Distance)이 navigation task 성공률에 미치는 영향을 정량적으로 측정한 연구는 아직 부재**하다. 이는 본 논문의 C2 기여(end-to-end pipeline)가 메우는 간극 중 하나이다.

### §2.7 종합: 본 논문이 기여하는 교차점

위 §2.1–§2.6을 종합하면, 기존 연구는 다음 네 가지 조건을 동시에 충족하는 작업을 수행한 바 없다: ①산업현장 보디캠 도메인, ② 카메라 전용(camera-only) 입력, ③ 9개 atomic methods의 일관된 비교 평가, ④ 재구성 품질과 로봇 내비게이션 성공률을 잇는 end-to-end 평가. 본 논문은 이 4-way intersection을 최초로 채운다.

---

## 2. 정식 Annotated Bibliography (IEEE 형식)

> 모든 인용은 IEEE 스타일(저자, 논문명, 게재지, 연도) 기준. ★ = Thesis 핵심 지지 문헌.

---

### A. 9 Atomic Methods (Core Baselines)

**[1]** J. L. Schönberger and J.-M. Frahm, "Structure-from-Motion Revisited," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, Las Vegas, NV, 2016, pp. 4104–4113. doi: https://doi.org/10.1109/CVPR.2016.445
- **Annotation:** 점진적 SfM의 de facto 표준. SIFT 특징점 기반 기하 검증 및 Bundle Adjustment를 결합하여 넓은 범위의 데이터셋에서 강건한 카메라 자세와 희소 점군을 추정한다.
- **Stance:** Neutral baseline (H-Worst P1 구성 요소)
- **Assigned Sections:** §1.2, §2.1, §3.3 Tab 1, §4.3

**[2]** L. Pan, D. Baráth, M. Pollefeys, and J. L. Schönberger, "Global Structure-from-Motion Revisited," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2407.20219.
- **Annotation:** Global SfM에서 회전 평균화와 삼각측량을 단일 global positioning step으로 병합함으로써 COLMAP 대비 수십 배 빠른 속도를 달성한다. COLMAP의 후속 작업이나 hand-crafted 특징점 의존성은 유지된다.
- **Stance:** Neutral baseline (SfM 계열)
- **Assigned Sections:** §2.1, §3.3 Tab 1, §4.3

**[3]** S. Wang, V. Leroy, Y. Cabon, B. Chidlovskii, and J. Revaud, "DUSt3R: Geometric 3D Vision Made Easy," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2024, arXiv:2312.14132.
- **Annotation:** 두 이미지 간 dense 3D pointmap regression을 통해 카메라 파라미터 없이 pairwise 3D 재구성을 단일 순전파로 수행하는 end-to-end 학습 기반 방법. Sparse keypoint 의존성을 완전히 우회한다.
- **Stance:** Supports thesis (deep learning matching > hand-crafted)
- **Assigned Sections:** §2.2, §3.3 Tab 1, §4.3

**[4]** V. Leroy, Y. Cabon, and J. Revaud, "Grounding Image Matching in 3D with MASt3R," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2406.09756.
- **Annotation:** DUSt3R에 multi-view scale-aware matching loss를 추가하여 장거리 대응 정확도를 개선한 후속 모델. 3D 공간 내에서 픽셀 대응을 직접 grounding함으로써 기하학적 일관성이 향상된다.
- **Stance:** Supports thesis (deep matching)
- **Assigned Sections:** §2.2, §3.3 Tab 1, §4.3

**[5]** Z. Teed and J. Deng, "DROID-SLAM: Deep Visual SLAM for Monocular, Stereo, and RGB-D Cameras," in *Proc. Advances in Neural Information Processing Systems (NeurIPS)*, 2021.
- **Annotation:** Dense optical flow 기반 재귀적 Bundle Adjustment를 통해 단안·스테레오·RGB-D를 통합 처리하는 deep SLAM. 동적 시나리오가 포함된 학습 데이터를 활용하여 classical SfM 대비 Cluster B(동적 물체) 조건에서 강건한 추적 성능을 보인다.
- **Stance:** Supports thesis (deep SLAM > classical SfM in dynamic scenes)
- **Assigned Sections:** §2.3, §3.3 Tab 1, §4.3

**[6]** L. Lipson, Z. Teed, and J. Deng, "Deep Patch Visual SLAM," in *Proc. European Conf. Computer Vision (ECCV)*, 2024, arXiv:2408.01654.
- **Annotation:** Patch-graph SLAM 구조로 DROID-SLAM 대비 2.5배 빠른 속도와 5–7 GB의 낮은 GPU 메모리를 달성한다. 실시간 처리를 위한 경량 deep SLAM의 가능성을 시연한다.
- **Stance:** Supports thesis (low-mem deep SLAM)
- **Assigned Sections:** §2.3, §3.3 Tab 1, §4.3

**[7] ★** R. Murai, E. Dexheimer, and A. J. Davison, "MASt3R-SLAM: Real-Time Dense SLAM with 3D Reconstruction Priors," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2025, arXiv:2412.12392, pp. 16695–16705.
- **Annotation:** MASt3R prior를 실시간 SLAM에 통합하여 카메라 모델 가정 없이 15 FPS의 밀집 재구성을 달성한다. 사전등록 가설 H-Best(P9) 파이프라인의 pose 구성 요소이며, 산업현장 Cluster A/B/C 조건에서의 강건성이 본 논문의 핵심 실험 대상이다.
- **Stance:** **Strongly supports thesis** (H-Best pre-registration)
- **Assigned Sections:** §2.3, §3.3 Tab 1, §4.3, §5.2

**[8]** B. Kerbl, G. Kopanas, T. Leimkühler, and G. Drettakis, "3D Gaussian Splatting for Real-Time Radiance Field Rendering," *ACM Trans. Graphics (SIGGRAPH)*, vol. 42, no. 4, 2023. doi: https://doi.org/10.1145/3592433
- **Annotation:** 이방성 3D Gaussian 기본 요소를 rasterization으로 렌더링하여 NeRF 대비 수십 배 빠른 novel-view synthesis를 달성한다. 사전등록 가설 H-Worst(P1) 및 rep cross-ablation(P8)의 표현 구성 요소.
- **Stance:** Neutral baseline (volumetric representation)
- **Assigned Sections:** §2.4, §3.3 Tab 1, §4.3

**[9] ★** B. Huang, Z. Yu, A. Chen, A. Geiger, and S. Gao, "2D Gaussian Splatting for Geometrically Accurate Radiance Fields," in *Proc. ACM SIGGRAPH*, 2024. doi: https://doi.org/10.1145/3641519.3657428
- **Annotation:** 표면 정렬 2D disk를 기본 요소로 사용하여 planar prior를 부여하고 기하학적 정확도를 향상시킨다. 산업현장의 평면 dominant geometry와 정합성이 높으며, H-Best(P9) 파이프라인의 표현 구성 요소.
- **Stance:** **Strongly supports thesis** (H-Best + §5.3 planar prior argument)
- **Assigned Sections:** §2.4, §3.3 Tab 1, §4.3, §5.3

---

### B. Feature Description & Reconstruction Background

**[10]** D. G. Lowe, "Distinctive Image Features from Scale-Invariant Keypoints," *Int. J. Computer Vision (IJCV)*, vol. 60, no. 2, pp. 91–110, 2004. doi: https://doi.org/10.1023/B:VISI.0000029664.99615.94
- **Annotation:** SIFT 특징 검출·기술자의 원 제안 논문. Textureless 환경에서의 SIFT 한계를 §2.1에서 지적하는 근거가 되는 기저 문헌.
- **Stance:** Background (hand-crafted feature genealogy)
- **Assigned Sections:** §2.1

**[11]** A. Dai, A. X. Chang, M. Savva, M. Halber, T. Funkhouser, and M. Nießner, "ScanNet: Richly-Annotated 3D Reconstructions of Indoor Scenes," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2017. doi: https://doi.org/10.1109/CVPR.2017.261
- **Annotation:** 실내 3D 재구성 벤치마크의 표준으로, 정돈된 실내 환경(텍스처 풍부, 정적, 균일 조명)을 제공한다. 본 논문이 "일반 도메인 벤치마크가 산업현장 적용성을 보장하지 않는다"는 gap argument를 뒷받침하는 contrast example.
- **Stance:** Contrast (general benchmark, does NOT represent industrial domain)
- **Assigned Sections:** §1.2

**[12]** J. Straub *et al.*, "The Replica Dataset: A Digital Replica of Indoor Spaces," arXiv:1906.05797, 2019.
- **Annotation:** 고품질 실내 공간 디지털 복제 데이터셋. ScanNet과 함께 "정돈된 실내 도메인" 벤치마크의 대표로서 산업현장 적용의 gap argument를 지지한다.
- **Stance:** Contrast (general benchmark)
- **Assigned Sections:** §1.2

---

### C. Preprocessing & Tool References

**[13]** N. Ravi *et al.*, "SAM 2: Segment Anything in Images and Videos," arXiv:2408.00714, 2024.
- **Annotation:** 이미지와 비디오에서 임의의 객체를 프롬프트 기반으로 분할하는 foundation model. 본 논문 §3.2 전처리 모듈에서 동적 물체(작업자, 자재) 마스크 자동 생성 및 §4.5e ablation에 사용.
- **Stance:** Tool reference
- **Assigned Sections:** §3.2, §4.5e

**[14]** G. Jocher, A. Chaurasia, and J. Qiu, "Ultralytics YOLOv8," GitHub: ultralytics/ultralytics, version 8.0.0, 2023. [Online]. Available: https://github.com/ultralytics/ultralytics
- **Annotation:** 실시간 객체 탐지 및 instance segmentation의 사실상 표준. SAM2와 병행하여 동적 물체 마스크 생성 파이프라인의 후보 구현체.
- **Stance:** Tool reference
- **Assigned Sections:** §3.2, §4.5e

**[15]** S. Pertuz, D. Puig, and M. A. García, "Analysis of Focus Measure Operators for Shape-from-Focus," *Pattern Recognition*, vol. 46, no. 5, pp. 1415–1432, 2013. doi: https://doi.org/10.1016/j.patcog.2012.11.011
- **Annotation:** Laplacian variance를 포함한 다양한 focus measure 연산자를 체계적으로 비교 평가한다. 본 논문 §3.2의 sharpness threshold 기반 blur 프레임 제거 모듈의 근거 문헌.
- **Stance:** Tool reference (preprocessing)
- **Assigned Sections:** §3.2

**[16]** M. Kazhdan, M. Bolitho, and H. Hoppe, "Poisson Surface Reconstruction," in *Proc. Symp. Geometry Processing (SGP)*, 2006, pp. 61–70.
- **Annotation:** 법선 벡터가 주어진 점군으로부터 부드러운 폐쇄 곡면 메시를 추출하는 Poisson 방정식 기반 방법. 본 논문 §3.7에서 pose-only SfM 방법의 희소 점군으로부터 mesh를 추출할 때 사용.
- **Stance:** Tool reference (mesh extraction)
- **Assigned Sections:** §3.7

**[17]** A. Guédon and V. Lepetit, "SuGaR: Surface-Aligned Gaussian Splatting for Efficient 3D Mesh Reconstruction and High-Quality Mesh Rendering," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2024, arXiv:2311.12775.
- **Annotation:** 3D Gaussian Splatting에서 surface alignment regularization을 부여하고 Poisson reconstruction으로 mesh를 추출한다. 본 논문 §3.7에서 3DGS configurations (P1, P3, P4, P6, P8)의 mesh 추출 도구로 사용 (Alg 3).
- **Stance:** Tool reference (mesh extraction for 3DGS)
- **Assigned Sections:** §3.7

---

### D. Planning & Navigation

**[18]** S. Karaman and E. Frazzoli, "Sampling-based Algorithms for Optimal Motion Planning," *Int. J. Robotics Research (IJRR)*, vol. 30, no. 7, pp. 846–894, 2011. doi: https://doi.org/10.1177/0278364911406761
- **Annotation:** RRT*를 포함한 점근적 최적 샘플링 기반 경로 계획 알고리즘을 제안한다. 본 논문 §3.7 및 §4.6의 IsaacSim navigation 평가에서 경로 계획기로 사용.
- **Stance:** Tool reference (planner)
- **Assigned Sections:** §3.7, §4.6

---

### E. Industrial Domain Gap

**[19]** F. Bosché, "Automated Recognition of 3D CAD Model Objects in Laser Scans and Calculation of As-Built Dimensions for Dimensional Compliance Control in Construction," *Adv. Engineering Informatics*, vol. 24, no. 1, pp. 107–118, 2010. doi: https://doi.org/10.1016/j.aei.2009.08.006
- **Annotation:** 레이저 스캐닝 점군에서 CAD 모델 객체를 자동 인식하는 Scan-vs-BIM 방법론의 선구적 연구. LiDAR 의존 산업현장 재구성의 대표 사례로, 본 논문의 camera-only 접근과의 도메인 gap 대조에 사용.
- **Stance:** Gap evidence (LiDAR-based; camera-only gap을 부각)
- **Assigned Sections:** §2.5

**[20]** J. Xue, X. Hou, and Y. Zeng, "Review of Image-Based 3D Reconstruction of Building for Automated Construction Progress Monitoring," *Applied Sciences*, vol. 11, no. 17, p. 7840, 2021. doi: https://doi.org/10.3390/app11177840
- **Annotation:** 이미지 기반 건설현장 진도 모니터링을 위한 3D 재구성 방법론을 체계적으로 종합한 review. UAV·고정 카메라·SfM·MVS 등 다양한 photogrammetric 파이프라인을 분류·비교하나, 보디캠(body-worn) 시나리오와 최신 신경 3D 표현(3DGS/2DGS, deep SLAM)은 다루지 않는다. 본 논문 §2.5의 카메라 기반 산업현장 재구성 gap argument의 review 측 근거.
- **Stance:** Gap evidence (image-based 건설 모니터링 review)
- **Assigned Sections:** §2.5
- **Verification:** CrossRef + OpenAlex 모두 일치 (2026-05-11 confirmed). 이전 "Braun et al." 표기는 WebSearch 결과 오인 → 정정.

**[21]** A. Sun, X. An, P. Li, M. Lv, and W. Liu, "Near Real-Time 3D Reconstruction of Construction Sites Based on Surveillance Cameras," *Buildings*, vol. 15, no. 4, p. 567, 2025. doi: https://doi.org/10.3390/buildings15040567
- **Annotation:** 고정 감시 카메라 영상으로부터 준-실시간(near real-time) 3D 재구성을 수행하는 SfM 기반 파이프라인. Camera-only 산업현장 재구성의 최신 사례로 본 논문의 보디캠 도메인 시나리오와 가장 근접한 선행 연구이나, 동적 환경 강건성과 신경 3D 표현(3DGS/2DGS)·deep SLAM과의 비교는 다루지 않는다.
- **Stance:** Gap evidence (camera-only 산업현장 재구성 최신 사례)
- **Assigned Sections:** §2.5
- **Verification:** CrossRef + OpenAlex 모두 일치 (2026-05-11 confirmed). 이전 "S. Jiang, D. Jiang, W. Jiang" 표기는 WebSearch 결과 오인 → 정정.

---

### F. Mechanism Support

**[22]** D. Verbin, P. Hedman, B. Mildenhall, T. Zickler, J. T. Barron, and P. P. Srinivasan, "Ref-NeRF: Structured View-Dependent Appearance for Neural Radiance Fields," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2022. doi: https://doi.org/10.1109/CVPR52688.2022.00541
- **Annotation:** Photometric loss만으로는 specular·glossy 표면의 외관을 정확히 재현하기 어렵다는 한계를 분석하고, 반사 방향 기반 radiance 파라미터화로 이를 완화한다. Cluster C(Photometric Drift) 및 Cluster A.2(Reflective)의 메커니즘 근거 문헌.
- **Stance:** Supports Cluster A.2 & C mechanism argument
- **Assigned Sections:** §3.5, §5.2

**[23]** B. Bescos, J. M. Fácil, J. Civera, and J. Neira, "DynaSLAM: Tracking, Mapping, and Inpainting in Dynamic Scenes," *IEEE Robotics and Automation Letters (RA-L)*, vol. 3, no. 4, pp. 4076–4083, 2018. doi: https://doi.org/10.1109/LRA.2018.2860039
- **Annotation:** 마스크 기반으로 동적 객체를 제거하여 SLAM의 pose estimation 정확도를 향상시킨 선구적 연구. Classical SLAM이 동적 객체(Cluster B.1)에 의해 catastrophic failure에 취약함을 입증하는 메커니즘 근거.
- **Stance:** Supports Cluster B mechanism argument
- **Assigned Sections:** §3.5, §5.2

**[24]** A. Romanoni and M. Matteucci, "TAPA-MVS: Textureless-Aware PAtchMatch Multi-View Stereo," in *Proc. IEEE/CVF Int. Conf. Computer Vision (ICCV)*, 2019. doi: https://doi.org/10.1109/ICCV.2019.01051
- **Annotation:** Textureless 영역에서 PatchMatch MVS의 매칭 실패를 분석하고 planar prior를 이용한 개선을 제안한다. Cluster A.1(Textureless)의 feature matching 실패 메커니즘을 지지하는 근거.
- **Stance:** Supports Cluster A.1 mechanism argument
- **Assigned Sections:** §3.5, §5.2

**[25]** P. Bergmann, M. Fauser, D. Sattlegger, and C. Steger, "MVTec AD — A Comprehensive Real-World Dataset for Unsupervised Anomaly Detection," in *Proc. IEEE/CVF Conf. Computer Vision and Pattern Recognition (CVPR)*, 2019. doi: https://doi.org/10.1109/CVPR.2019.00982
- **Annotation:** 산업 표면 결함(오염, 긁힘, 이물질 등) 탐지를 위한 포괄적 벤치마크 데이터셋. §4.5d의 오염(Cluster A.3) 마스크 알고리즘 설계 및 정당화에 활용되는 배경 문헌.
- **Stance:** Supports Cluster A.3 (contamination) ablation design
- **Assigned Sections:** §3.5, §4.5d

---

### G. Statistical Methods

**[26]** H. R. Künsch, "The Jackknife and the Bootstrap for General Stationary Observations," *Annals of Statistics*, vol. 17, no. 3, pp. 1217–1261, 1989. doi: https://doi.org/10.1214/aos/1176347265
- **Annotation:** Moving-block bootstrap의 원 제안 논문. 연속 관측값으로 이루어진 블록을 복원 추출하여 시계열의 temporal correlation을 보존하면서 표준 오차와 신뢰 구간을 추정한다. **§4.4의 primary statistical test 근거 문헌** (outline rev2에서 오귀속된 "Politis & Romano 1994" → 본 문헌으로 수정).
- **Stance:** Methods convention (statistical standard)
- **Assigned Sections:** §4.4

**[27]** D. N. Politis and J. P. Romano, "The Stationary Bootstrap," *J. American Statistical Association*, vol. 89, no. 428, pp. 1303–1313, 1994. doi: https://doi.org/10.1080/01621459.1994.10476870
- **Annotation:** 무작위 길이 블록(geometrically distributed block length)을 사용하는 Stationary Bootstrap을 제안한다. Künsch [26]의 moving-block bootstrap과 구분되며, §4.4에서 sensitivity analysis 보조 참고문헌으로 병기 가능.
- **Stance:** Methods convention (secondary / sensitivity check)
- **Assigned Sections:** §4.4

---

### H. Validity Framework

**[28]** C. Wohlin, P. Runeson, M. Höst, M. C. Ohlsson, B. Regnell, and A. Wesslén, *Experimentation in Software Engineering*, 2nd ed. Berlin, Germany: Springer, 2012.
- **Annotation:** 소프트웨어·시스템 공학 분야 실험 연구의 표준 교과서. Internal / External / Construct / Conclusion 4-threat validity 분류 체계와 각 threat에 대한 mitigation 전략을 체계화한다. 본 논문 §5.6 Threats to Validity의 primary framework로 채택.
- **Stance:** Methods convention (validity framework primary)
- **Assigned Sections:** §5.6

**[29]** P. Runeson and M. Höst, "Guidelines for Conducting and Reporting Case Study Research in Software Engineering," *Empirical Software Engineering*, vol. 14, no. 2, pp. 131–164, 2009. doi: https://doi.org/10.1007/s10664-008-9102-8
- **Annotation:** 소프트웨어 공학 case study 연구의 설계·실행·보고 가이드라인. 3개 산업현장이라는 소규모 case study 성격을 보완하는 외부타당도 논의의 secondary framework로 §5.6 External validity 부분에 활용.
- **Stance:** Methods convention (case study external validity, secondary)
- **Assigned Sections:** §5.6

---

## 3. 갱신된 Evidence Map

| Source | IEEE ref | Assigned Section(s) | Stance | Status |
|---|---|---|---|---|
| Schönberger16 (COLMAP) | [1] | §1.2, §2.1, §3.3, §4.3 | Neutral baseline | ✅ 확정 |
| Pan24 (GLOMAP) | [2] | §2.1, §3.3, §4.3 | Neutral baseline | ✅ ECCV 2024 확정 |
| Wang24 (DUSt3R) | [3] | §2.2, §3.3, §4.3 | Supports thesis | ✅ CVPR 2024 확정 |
| Leroy24 (MASt3R) | [4] | §2.2, §3.3, §4.3 | Supports thesis | ✅ ECCV 2024 확정 |
| Teed21 (DROID-SLAM) | [5] | §2.3, §3.3, §4.3 | Supports thesis | ✅ NeurIPS 2021 확정 |
| Lipson24 (DPV-SLAM) | [6] | §2.3, §3.3, §4.3 | Supports thesis | ✅ ECCV 2024 확정 |
| Murai25 (MASt3R-SLAM) | [7] | §2.3, §3.3, §4.3, §5.2 | **Strongly supports** | ✅ CVPR 2025 확정 |
| Kerbl23 (3DGS) | [8] | §2.4, §3.3, §4.3 | Neutral baseline | ✅ SIGGRAPH 2023 확정 |
| Huang24 (2DGS) | [9] | §2.4, §3.3, §4.3, §5.3 | **Strongly supports** | ✅ SIGGRAPH 2024 확정 |
| Lowe04 (SIFT) | [10] | §2.1 | Background | ✅ IJCV 2004 확정 |
| Dai17 (ScanNet) | [11] | §1.2 | Contrast | ✅ CVPR 2017 확정 |
| Straub19 (Replica) | [12] | §1.2 | Contrast | ✅ arXiv 2019 확정 |
| SAM2 [Ravi24] | [13] | §3.2, §4.5e | Tool reference | ✅ arXiv 2408.00714 확정 |
| YOLOv8 [Jocher23] | [14] | §3.2, §4.5e | Tool reference | ✅ GitHub 2023 확정 |
| Pertuz13 (sharpness) | [15] | §3.2 | Tool reference | ✅ Pattern Recog. 2013 확정 |
| Kazhdan06 (Poisson recon) | [16] | §3.7 | Tool reference | ✅ SGP 2006 확정 |
| Guédon24 (SuGaR) | [17] | §3.7 | Tool reference | ✅ CVPR 2024 확정 |
| Karaman11 (RRT*) | [18] | §3.7, §4.6 | Tool reference | ✅ IJRR 2011 확정 |
| Bosché10 (industrial BIM) | [19] | §2.5 | Gap evidence | ✅ Adv. Eng. Inf. 2010 확정 |
| Xue21 (image-based review) | [20] | §2.5 | Gap evidence (review) | ✅ Applied Sciences 2021 확정 (CrossRef+OpenAlex 2026-05-11) |
| Sun25 (surveillance cam recon) | [21] | §2.5 | Gap evidence (recent) | ✅ Buildings 2025 확정 (CrossRef+OpenAlex 2026-05-11) |
| Verbin22 (Ref-NeRF) | [22] | §3.5, §5.2 | Supports Cluster A.2/C | ✅ CVPR 2022 확정 |
| Bescos18 (DynaSLAM) | [23] | §3.5, §5.2 | Supports Cluster B | ✅ RA-L 2018 확정 |
| Romanoni19 (TAPA-MVS) | [24] | §3.5, §5.2 | Supports Cluster A.1 | ✅ ICCV 2019 확정 |
| Bergmann19 (MVTec AD) | [25] | §3.5, §4.5d | Supports Cluster A.3 | ✅ CVPR 2019 확정 |
| Künsch89 (block bootstrap) | [26] | §4.4 | Statistical standard | ✅ Ann. Stat. 1989 확정 (**outline 수정 필요**) |
| Politis94 (stationary bootstrap) | [27] | §4.4 | Secondary / sensitivity | ✅ JASA 1994 확정 |
| Wohlin12 (Experimentation in SE) | [28] | §5.6 | Validity framework primary | ✅ Springer 2nd ed. 2012 확정 |
| Runeson09 (case study guidelines) | [29] | §5.6 | Case study external validity | ✅ Empirical SE 2009 확정 |

**[TBD] 해소 현황:**
| 카테고리 | 상태 |
|---|---|
| Industrial BIM / construction monitoring | ✅ [19] Bosché10 + [20] Xue21 review + [21] Sun25 (둘 다 인용 확정; 저자 fabrication 정정 2026-05-11) |
| Photometric loss limits | ✅ [22] Verbin22 (Ref-NeRF) |
| Dynamic SLAM survey | ✅ [23] Bescos18 (DynaSLAM) |
| Textureless feature matching | ✅ [24] Romanoni19 (TAPA-MVS) |
| Specular detection | ✅ [22] Verbin22 (photometric failure 포함) |
| Anomaly segmentation | ✅ [25] Bergmann19 (MVTec AD) |
| Bootstrap statistics | ✅ [26] Künsch89 + [27] Politis94 |
| Validity framework | ✅ [28] Wohlin12 primary + [29] Runeson09 case study secondary (2026-05-11 확정) |

---

## 4. PAPER_OUTLINE.md 수정 권고

다음 항목은 본 lit-review 결과에 따라 PAPER_OUTLINE.md §4.4에 반영이 필요합니다:

> **§4.4 수정 (필수):** "Politis & Romano (1994) moving-block bootstrap" → "Künsch (1989) moving-block bootstrap [26]" 으로 귀속 수정. Politis & Romano (1994) [27]는 별개의 Stationary Bootstrap으로 sensitivity analysis 보조 참고문헌으로 유지.
>
> **§2.5 수정 (반영 권고):** "Son 등[20]의 리뷰" → "Xue 등[20]의 image-based review + Sun 등[21]의 surveillance camera 사례" 듀얼 인용으로 교체. 본문 단락은 lit-review §2.5 참조. *(저자명은 2026-05-11 CrossRef/OpenAlex로 확정 — 이전 Braun/Jiang 표기 fabrication 정정.)*

---

## 5. Next-Step Roadmap (lit-review 단계 완료 후)

```
[현재] LIT_REVIEW.md 완료 ✅
   │
   ├─→ PAPER_OUTLINE.md §4.4 bootstrap 귀속 수정 (즉시)
   │
   ├─→ [20] 후보 A·B 둘 다 인용 확정 ✅ (Xue21 + Sun25 — DOI 검증 2026-05-11)
   │
   ├─→ §5.6 Validity framework: [28] Wohlin12 + [29] Runeson09 확정 ✅
   │
   ├─→ 실험 단계: 9 pipeline configurations 실행, §4 데이터 산출
   │
   └─→ /ars-full 또는 수동 본문 작성 (§3 → §4 → §5 순)
```
