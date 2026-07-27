<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dashboard') — Kasir Digital</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        :root{--primary:#4F46E5;--primary-dark:#4338CA;--primary-light:#EEF2FF;--accent:#06B6D4;--success:#10B981;--success-light:#ECFDF5;--warning:#F59E0B;--warning-light:#FFFBEB;--danger:#EF4444;--danger-light:#FEF2F2;--sidebar-bg:#0F172A;--sidebar-border:rgba(255,255,255,0.06);--sidebar-hover:rgba(255,255,255,0.07);--sidebar-active-bg:rgba(79,70,229,0.18);--sidebar-text:#64748B;--sidebar-text-h:#94A3B8;--sidebar-text-active:#C7D2FE;--body-bg:#F1F5F9;--card-bg:#FFF;--text-primary:#1E293B;--text-secondary:#64748B;--text-muted:#94A3B8;--border:#E2E8F0;--border-h:#CBD5E1;--shadow-sm:0 1px 2px rgba(0,0,0,0.05);--shadow:0 1px 3px rgba(0,0,0,0.1),0 1px 2px rgba(0,0,0,0.06);--shadow-md:0 4px 6px -1px rgba(0,0,0,0.1),0 2px 4px -2px rgba(0,0,0,0.1);--shadow-lg:0 10px 15px -3px rgba(0,0,0,0.1),0 4px 6px -4px rgba(0,0,0,0.1);--radius-sm:0.5rem;--radius:0.75rem;--radius-lg:1rem;--sidebar-w:260px;--header-h:62px;--tr:all 0.18s cubic-bezier(0.4,0,0.2,1)}
        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
        body{font-family:'Inter',-apple-system,BlinkMacSystemFont,sans-serif;background:var(--body-bg);color:var(--text-primary);font-size:.875rem;line-height:1.5;-webkit-font-smoothing:antialiased}

        /* ═══════════════ SIDEBAR ═══════════════ */
        .sidebar{position:fixed;top:0;left:0;width:var(--sidebar-w);height:100vh;background:var(--sidebar-bg);display:flex;flex-direction:column;z-index:100;overflow:hidden}
        .sidebar::before{content:'';position:absolute;top:0;left:0;right:0;height:200px;background:linear-gradient(160deg,rgba(79,70,229,0.12) 0%,transparent 70%);pointer-events:none}
        .sidebar-logo{padding:1.25rem 1.25rem .875rem;border-bottom:1px solid var(--sidebar-border);display:flex;align-items:center;gap:.75rem;position:relative;z-index:1}
        .logo-icon{width:38px;height:38px;background:linear-gradient(135deg,#4F46E5 0%,#7C3AED 100%);border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0;box-shadow:0 4px 14px rgba(79,70,229,.45)}
        .logo-icon svg{width:20px;height:20px;color:#fff;fill:currentColor}
        .logo-text{flex:1;min-width:0}
        .logo-name{color:#F1F5F9;font-size:.9375rem;font-weight:800;letter-spacing:-.02em}
        .logo-sub{color:var(--sidebar-text);font-size:.6875rem;margin-top:.1rem;letter-spacing:.01em}
        .sidebar-nav{flex:1;padding:.875rem .625rem;overflow-y:auto;scrollbar-width:none}
        .sidebar-nav::-webkit-scrollbar{display:none}
        .nav-label{color:var(--sidebar-text);font-size:.6rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;padding:.875rem .75rem .375rem;display:block;opacity:.6}
        .nav-item{display:flex;align-items:center;gap:.6875rem;padding:.5625rem .75rem;border-radius:var(--radius-sm);color:var(--sidebar-text-h);text-decoration:none;font-size:.8125rem;font-weight:500;transition:var(--tr);margin-bottom:.125rem;position:relative;overflow:hidden}
        .nav-item:hover{background:var(--sidebar-hover);color:#CBD5E1}
        .nav-item.active{background:var(--sidebar-active-bg);color:var(--sidebar-text-active);font-weight:600}
        .nav-item.active::before{content:'';position:absolute;left:0;top:20%;height:60%;width:3px;background:var(--primary);border-radius:0 3px 3px 0}
        .nav-icon{width:18px;height:18px;flex-shrink:0;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;opacity:.8}
        .nav-item.active .nav-icon,.nav-item:hover .nav-icon{opacity:1}
        .sidebar-footer{padding:.75rem .625rem;border-top:1px solid var(--sidebar-border)}
        .sidebar-user{display:flex;align-items:center;gap:.75rem;padding:.5rem .75rem;border-radius:var(--radius-sm)}
        .avatar{width:32px;height:32px;background:linear-gradient(135deg,#4F46E5,#7C3AED);border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;font-size:.6875rem;flex-shrink:0}
        .user-name{color:#CBD5E1;font-size:.8rem;font-weight:600}
        .user-role{color:var(--sidebar-text);font-size:.6875rem}

        /* ═══════════════ MAIN LAYOUT ═══════════════ */
        .main-wrap{margin-left:var(--sidebar-w);min-height:100vh;display:flex;flex-direction:column}
        .topbar{position:sticky;top:0;z-index:50;background:rgba(241,245,249,.85);backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);border-bottom:1px solid var(--border);height:var(--header-h);padding:0 1.5rem;display:flex;align-items:center;justify-content:space-between}
        .breadcrumb{display:flex;align-items:center;gap:.5rem;color:var(--text-muted);font-size:.8125rem}
        .breadcrumb a{color:var(--text-muted);text-decoration:none}
        .breadcrumb a:hover{color:var(--text-primary)}
        .breadcrumb-sep{color:var(--text-muted);opacity:.5}
        .breadcrumb-current{color:var(--text-secondary);font-weight:500}
        .topbar-right{display:flex;align-items:center;gap:.75rem}
        .date-chip{display:flex;align-items:center;gap:.375rem;color:var(--text-secondary);font-size:.8125rem;padding:.3125rem .75rem;background:#fff;border:1px solid var(--border);border-radius:100px;box-shadow:var(--shadow-sm)}
        .page-content{flex:1;padding:1.5rem}

        /* ═══════════════ PAGE HEADER ═══════════════ */
        .page-header{margin-bottom:1.5rem}
        .page-title{font-size:1.375rem;font-weight:800;color:var(--text-primary);letter-spacing:-.025em}
        .page-sub{color:var(--text-secondary);font-size:.8125rem;margin-top:.25rem}

        /* ═══════════════ CARDS ═══════════════ */
        .card{background:var(--card-bg);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow-sm);overflow:hidden}
        .card-header{padding:1rem 1.25rem;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
        .card-title{font-size:.9375rem;font-weight:700;color:var(--text-primary)}
        .card-body{padding:1.25rem}

        /* ═══════════════ KPI CARDS ═══════════════ */
        .kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem;margin-bottom:1.25rem}
        .kpi{background:var(--card-bg);border-radius:var(--radius);padding:1.25rem;border:1px solid var(--border);box-shadow:var(--shadow-sm);transition:var(--tr);position:relative;overflow:hidden}
        .kpi:hover{box-shadow:var(--shadow-md);transform:translateY(-2px)}
        .kpi::after{content:'';position:absolute;top:-20px;right:-20px;width:100px;height:100px;border-radius:50%;opacity:.05}
        .kpi.c-indigo::after{background:var(--primary)}
        .kpi.c-cyan::after{background:var(--accent)}
        .kpi.c-green::after{background:var(--success)}
        .kpi.c-amber::after{background:var(--warning)}
        .kpi-top{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:.875rem}
        .kpi-icon-wrap{width:42px;height:42px;border-radius:var(--radius-sm);display:flex;align-items:center;justify-content:center}
        .kpi-icon-wrap.c-indigo{background:var(--primary-light);color:var(--primary)}
        .kpi-icon-wrap.c-cyan{background:#ECFEFF;color:var(--accent)}
        .kpi-icon-wrap.c-green{background:var(--success-light);color:var(--success)}
        .kpi-icon-wrap.c-amber{background:var(--warning-light);color:var(--warning)}
        .kpi-icon-wrap svg{width:20px;height:20px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
        .kpi-label{font-size:.75rem;font-weight:500;color:var(--text-muted);text-transform:uppercase;letter-spacing:.04em}
        .kpi-value{font-size:1.625rem;font-weight:800;color:var(--text-primary);letter-spacing:-.03em;line-height:1.2}
        .kpi-value.sm{font-size:1.125rem}
        .kpi-badge{display:inline-flex;align-items:center;gap:.25rem;padding:.2rem .6rem;border-radius:100px;font-size:.6875rem;font-weight:600;margin-top:.5rem}

        /* ═══════════════ GRID HELPERS ═══════════════ */
        .g2{display:grid;grid-template-columns:2fr 1fr;gap:1rem}
        .g3{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem}
        .gc2{display:grid;grid-template-columns:repeat(2,1fr);gap:1rem}
        .mb-1{margin-bottom:.25rem}.mb-2{margin-bottom:.5rem}.mb-3{margin-bottom:.75rem}.mb-4{margin-bottom:1rem}
        .mt-1{margin-top:.25rem}.mt-2{margin-top:.5rem}.mt-3{margin-top:.75rem}.mt-4{margin-top:1rem}
        .d-flex{display:flex}.ai-c{align-items:center}.jb{justify-content:space-between}.je{justify-content:flex-end}
        .flex-1{flex:1}.gap-2{gap:.5rem}.gap-3{gap:.75rem}.gap-4{gap:1rem}
        .w-full{width:100%}.text-right{text-align:right}.text-center{text-align:center}
        .fw-5{font-weight:500}.fw-6{font-weight:600}.fw-7{font-weight:700}.fw-8{font-weight:800}
        .fs-xs{font-size:.75rem}.fs-sm{font-size:.8125rem}.fs-base{font-size:.875rem}
        .text-muted{color:var(--text-muted)}.text-secondary-c{color:var(--text-secondary)}
        .text-primary-c{color:var(--primary)}.text-success-c{color:var(--success)}.text-danger-c{color:var(--danger)}.text-warning-c{color:var(--warning)}
        .truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

        /* ═══════════════ TABLE ═══════════════ */
        .tbl-wrap{overflow-x:auto}
        table{width:100%;border-collapse:collapse}
        thead th{padding:.6875rem 1rem;text-align:left;font-size:.6875rem;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;background:#F8FAFC;border-bottom:1px solid var(--border);white-space:nowrap}
        tbody td{padding:.875rem 1rem;border-bottom:1px solid #F1F5F9;font-size:.875rem;color:var(--text-primary)}
        tbody tr:last-child td{border-bottom:none}
        tbody tr:hover td{background:#FAFBFC}

        /* ═══════════════ BADGES ═══════════════ */
        .badge{display:inline-flex;align-items:center;gap:.25rem;padding:.2rem .625rem;border-radius:100px;font-size:.6875rem;font-weight:600;white-space:nowrap}
        .b-success{background:var(--success-light);color:#059669}
        .b-warning{background:var(--warning-light);color:#D97706}
        .b-danger{background:var(--danger-light);color:var(--danger)}
        .b-primary{background:var(--primary-light);color:var(--primary)}
        .b-secondary{background:#F1F5F9;color:var(--text-secondary)}
        .b-cyan{background:#ECFEFF;color:#0891B2}
        .b-in{background:#ECFDF5;color:#059669}
        .b-out{background:#FEF2F2;color:#DC2626}

        /* ═══════════════ BUTTONS ═══════════════ */
        .btn{display:inline-flex;align-items:center;gap:.375rem;padding:.5rem 1rem;border-radius:var(--radius-sm);font-size:.875rem;font-weight:500;cursor:pointer;transition:var(--tr);border:1px solid transparent;text-decoration:none;white-space:nowrap;font-family:inherit;line-height:1.5}
        .btn-sm{padding:.3125rem .6875rem;font-size:.8125rem}
        .btn-lg{padding:.6875rem 1.375rem;font-size:.9375rem;font-weight:600}
        .btn-xl{padding:.875rem 1.75rem;font-size:1rem;font-weight:700}
        .btn-primary{background:var(--primary);color:#fff;border-color:var(--primary)}
        .btn-primary:hover{background:var(--primary-dark);border-color:var(--primary-dark);box-shadow:0 4px 14px rgba(79,70,229,.35)}
        .btn-success{background:var(--success);color:#fff}
        .btn-success:hover{background:#059669;box-shadow:0 4px 14px rgba(16,185,129,.35)}
        .btn-danger{background:var(--danger);color:#fff}
        .btn-danger:hover{background:#DC2626}
        .btn-warning{background:var(--warning);color:#fff}
        .btn-outline{background:transparent;border-color:var(--border);color:var(--text-primary)}
        .btn-outline:hover{background:#F8FAFC;border-color:var(--border-h)}
        .btn-ghost{background:transparent;border-color:transparent;color:var(--text-secondary)}
        .btn-ghost:hover{background:#F1F5F9;color:var(--text-primary)}
        .btn-icon{width:34px;height:34px;padding:0;justify-content:center}
        .btn:disabled{opacity:.5;cursor:not-allowed;pointer-events:none}

        /* ═══════════════ FORMS ═══════════════ */
        .form-group{margin-bottom:1rem}
        .form-label{display:block;font-size:.8125rem;font-weight:600;color:var(--text-primary);margin-bottom:.375rem}
        .req{color:var(--danger);margin-left:.2rem}
        .form-control{width:100%;padding:.5625rem .875rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-size:.875rem;color:var(--text-primary);background:#fff;transition:var(--tr);outline:none;font-family:inherit}
        .form-control:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(79,70,229,.12)}
        .form-control::placeholder{color:var(--text-muted)}
        .form-hint{font-size:.75rem;color:var(--text-muted);margin-top:.25rem}
        .input-icon{position:relative}
        .input-icon .form-control{padding-left:2.5rem}
        .input-icon svg{position:absolute;left:.75rem;top:50%;transform:translateY(-50%);opacity:.4;width:16px;height:16px;stroke:var(--text-primary);fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;pointer-events:none}
        .form-error{color:var(--danger);font-size:.75rem;margin-top:.25rem}

        /* ═══════════════ ALERTS ═══════════════ */
        .alert{padding:.875rem 1rem;border-radius:var(--radius-sm);font-size:.875rem;display:flex;align-items:flex-start;gap:.625rem;margin-bottom:1rem}
        .alert svg{width:16px;height:16px;flex-shrink:0;margin-top:.1rem}
        .alert-success{background:var(--success-light);color:#065F46;border:1px solid #A7F3D0}
        .alert-danger{background:var(--danger-light);color:#991B1B;border:1px solid #FECACA}
        .alert-warning{background:var(--warning-light);color:#92400E;border:1px solid #FDE68A}

        /* ═══════════════ MODAL ═══════════════ */
        .modal-ov{display:none;position:fixed;inset:0;background:rgba(15,23,42,.6);z-index:200;align-items:center;justify-content:center;backdrop-filter:blur(6px)}
        .modal-ov.open{display:flex}
        .modal{background:#fff;border-radius:var(--radius-lg);width:90%;max-width:480px;box-shadow:0 25px 50px rgba(0,0,0,.25);animation:mIn .2s cubic-bezier(0.34,1.56,0.64,1)}
        .modal-sm{max-width:380px}
        @keyframes mIn{from{opacity:0;transform:scale(.92) translateY(12px)}to{opacity:1;transform:scale(1) translateY(0)}}
        .modal-header{padding:1.125rem 1.5rem;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
        .modal-title{font-size:1rem;font-weight:700;color:var(--text-primary)}
        .modal-body{padding:1.375rem 1.5rem}
        .modal-footer{padding:.875rem 1.5rem;border-top:1px solid var(--border);display:flex;align-items:center;justify-content:flex-end;gap:.625rem}

        /* ═══════════════ CHART ═══════════════ */
        .chart-wrap{position:relative}
        .chart-wrap canvas{max-height:240px}

        /* ═══════════════ TIMELINE ═══════════════ */
        .timeline-item{display:flex;gap:.875rem;padding:.875rem 0;border-bottom:1px solid #F1F5F9}
        .timeline-item:last-child{border-bottom:none}
        .tl-dot{width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:.875rem}
        .tl-dot.in{background:var(--success-light);color:var(--success)}
        .tl-dot.out{background:var(--danger-light);color:var(--danger)}
        .tl-body{flex:1;min-width:0}
        .tl-title{font-size:.875rem;font-weight:600;color:var(--text-primary)}
        .tl-meta{font-size:.75rem;color:var(--text-muted);margin-top:.125rem}
        .tl-right{text-align:right;flex-shrink:0}
        .tl-qty{font-size:.9375rem;font-weight:800}
        .tl-qty.in{color:var(--success)}
        .tl-qty.out{color:var(--danger)}
        .tl-cost{font-size:.6875rem;color:var(--text-muted);margin-top:.125rem}

        /* ═══════════════ POS ═══════════════ */
        .pos-layout{display:grid;grid-template-columns:1fr 340px;gap:1rem;height:calc(100vh - var(--header-h) - 3rem);min-height:500px}
        .pos-products{background:#fff;border-radius:var(--radius);border:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden;box-shadow:var(--shadow-sm)}
        .pos-top{padding:.875rem 1rem;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:.75rem}
        .cat-tabs{padding:.625rem 1rem;border-bottom:1px solid var(--border);display:flex;gap:.5rem;overflow-x:auto;scrollbar-width:none}
        .cat-tabs::-webkit-scrollbar{display:none}
        .cat-tab{padding:.3125rem .875rem;border-radius:100px;border:1px solid var(--border);background:#fff;font-size:.8rem;font-weight:500;color:var(--text-secondary);cursor:pointer;transition:var(--tr);white-space:nowrap;font-family:inherit}
        .cat-tab:hover{border-color:var(--primary);color:var(--primary)}
        .cat-tab.on{background:var(--primary);color:#fff;border-color:var(--primary)}
        .prod-grid{flex:1;padding:.875rem;display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:.625rem;overflow-y:auto;align-content:start}
        .prod-card{border:2px solid var(--border);border-radius:var(--radius);padding:.875rem;cursor:pointer;transition:var(--tr);background:#fff;position:relative;user-select:none}
        .prod-card:not(.sold-out):hover{border-color:var(--primary);box-shadow:0 0 0 3px rgba(79,70,229,.1);transform:translateY(-2px)}
        .prod-card:not(.sold-out):active{transform:scale(.97)}
        .prod-card.sold-out{opacity:.5;cursor:not-allowed}
        .prod-emoji{width:44px;height:44px;border-radius:var(--radius-sm);display:flex;align-items:center;justify-content:center;font-size:1.375rem;margin-bottom:.5rem}
        .prod-name{font-size:.8rem;font-weight:700;color:var(--text-primary);line-height:1.3;margin-bottom:.3125rem}
        .prod-price{font-size:.875rem;font-weight:800;color:var(--primary)}
        .prod-stock{font-size:.6875rem;margin-top:.25rem}
        .pos-cart{background:#fff;border-radius:var(--radius);border:1px solid var(--border);display:flex;flex-direction:column;overflow:hidden;box-shadow:var(--shadow-sm)}
        .cart-hd{padding:.875rem 1.125rem;background:linear-gradient(135deg,var(--primary),#7C3AED);display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
        .cart-hd-title{color:#fff;font-weight:700;font-size:.9375rem;display:flex;align-items:center;gap:.5rem}
        .cart-count{background:rgba(255,255,255,.2);color:#fff;border-radius:100px;padding:.125rem .625rem;font-size:.8125rem;font-weight:700}
        .cart-items{flex:1;overflow-y:auto;padding:.625rem}
        .cart-empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:2rem;text-align:center;color:var(--text-muted)}
        .cart-item{display:flex;gap:.625rem;padding:.625rem;background:#F8FAFC;border-radius:var(--radius-sm);margin-bottom:.375rem;border:1px solid #F1F5F9;transition:var(--tr)}
        .ci-info{flex:1;min-width:0}
        .ci-name{font-size:.8125rem;font-weight:700;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
        .ci-price{font-size:.75rem;color:var(--text-secondary);margin-top:.125rem}
        .qty-ctrl{display:flex;align-items:center;gap:.375rem;margin-top:.375rem}
        .qty-btn{width:22px;height:22px;border:1px solid var(--border);border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:1rem;line-height:1;color:var(--text-primary);transition:var(--tr);font-family:inherit}
        .qty-btn:hover{background:var(--primary);color:#fff;border-color:var(--primary)}
        .qty-n{font-size:.875rem;font-weight:800;min-width:18px;text-align:center}
        .cart-ft{padding:.875rem 1.125rem;border-top:1px solid var(--border);background:#F8FAFC;flex-shrink:0}
        .sum-row{display:flex;justify-content:space-between;font-size:.8125rem;color:var(--text-secondary);padding:.2rem 0}
        .sum-total{display:flex;justify-content:space-between;padding:.5rem 0 0;border-top:2px solid var(--border);margin-top:.375rem}
        .sum-total-lbl{font-size:.9375rem;font-weight:700;color:var(--text-primary)}
        .sum-total-val{font-size:1.125rem;font-weight:900;color:var(--primary)}
        .pay-method-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:.5rem}
        .pay-method-btn{padding:.625rem .875rem;border:2px solid var(--border);border-radius:var(--radius-sm);background:#fff;cursor:pointer;font-size:.8125rem;font-weight:500;color:var(--text-primary);text-align:center;transition:var(--tr);font-family:inherit}
        .pay-method-btn:hover{border-color:var(--primary);color:var(--primary)}
        .pay-method-btn.on{border-color:var(--primary);background:var(--primary-light);color:var(--primary);font-weight:700}
        .change-box{background:var(--success-light);border-radius:var(--radius-sm);padding:1rem;text-align:center;border:1px solid #A7F3D0}
        .change-lbl{font-size:.8125rem;color:var(--success);font-weight:500}
        .change-val{font-size:1.625rem;font-weight:900;color:var(--success);letter-spacing:-.03em}

        /* ═══════════════ PERIOD TABS ═══════════════ */
        .period-tabs{display:flex;background:#F1F5F9;border-radius:var(--radius-sm);padding:.25rem;gap:.25rem;width:max-content}
        .period-tab{flex:1;padding:.4375rem .875rem;border-radius:calc(var(--radius-sm) - 2px);font-size:.8125rem;font-weight:500;cursor:pointer;transition:var(--tr);color:var(--text-secondary);border:none;background:transparent;font-family:inherit;white-space:nowrap}
        .period-tab.on{background:#fff;color:var(--text-primary);font-weight:700;box-shadow:var(--shadow-sm)}

        /* ═══════════════ TOAST ═══════════════ */
        .toasts{position:fixed;top:1rem;right:1rem;z-index:999;display:flex;flex-direction:column;gap:.5rem}
        .toast{padding:.8125rem 1.125rem;border-radius:var(--radius-sm);background:var(--text-primary);color:#fff;font-size:.875rem;font-weight:500;box-shadow:var(--shadow-lg);display:flex;align-items:center;gap:.5rem;animation:tIn .25s cubic-bezier(0.34,1.56,0.64,1);max-width:300px}
        .t-success{background:var(--success)}
        .t-error{background:var(--danger)}
        .t-warning{background:var(--warning)}
        @keyframes tIn{from{opacity:0;transform:translateX(100%)}to{opacity:1;transform:translateX(0)}}

        /* ═══════════════ SCROLLBAR ═══════════════ */
        ::-webkit-scrollbar{width:4px;height:4px}
        ::-webkit-scrollbar-track{background:transparent}
        ::-webkit-scrollbar-thumb{background:var(--border);border-radius:2px}
        ::-webkit-scrollbar-thumb:hover{background:var(--border-h)}

        /* ═══════════════ MISC ═══════════════ */
        .divider{height:1px;background:var(--border);margin:1rem 0}
        .empty-state{text-align:center;padding:3rem 1rem;color:var(--text-muted)}
        .empty-icon{font-size:3rem;margin-bottom:.75rem}
        .empty-title{font-size:.9375rem;font-weight:600;color:var(--text-secondary);margin-bottom:.25rem}
        .empty-sub{font-size:.8125rem}
        .sold-out-badge{position:absolute;inset:0;background:rgba(255,255,255,.75);border-radius:calc(var(--radius) - 2px);display:flex;align-items:center;justify-content:center}
        .sold-out-text{font-size:.6875rem;font-weight:800;color:var(--danger);letter-spacing:.05em}
    </style>
    @stack('head')
</head>
<body>
<!-- ═══════════════ SIDEBAR ═══════════════ -->
<aside class="sidebar">
    <div class="sidebar-logo">
        <div class="logo-icon">
            <svg viewBox="0 0 24 24"><path d="M4 4h16v2H4V4zm0 4h16v12H4V8zm2 2v8h12v-8H6zm2 2h2v4H8v-4zm4 0h2v4h-2v-4z"/></svg>
        </div>
        <div class="logo-text">
            <div class="logo-name">Kasir Digital</div>
            <div class="logo-sub">Point of Sale System</div>
        </div>
    </div>

    <nav class="sidebar-nav">
        <span class="nav-label">Menu Utama</span>

        <a href="{{ route('dashboard') }}" class="nav-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
            <svg class="nav-icon" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
            Dashboard
        </a>

        <a href="{{ route('pos.index') }}" class="nav-item {{ request()->routeIs('pos.*') ? 'active' : '' }}">
            <svg class="nav-icon" viewBox="0 0 24 24"><path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            Kasir POS
        </a>

        <span class="nav-label">Inventaris</span>

        <a href="{{ route('products.index') }}" class="nav-item {{ request()->routeIs('products.*') ? 'active' : '' }}">
            <svg class="nav-icon" viewBox="0 0 24 24"><path d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            Produk
        </a>

        <a href="{{ route('categories.index') }}" class="nav-item {{ request()->routeIs('categories.*') ? 'active' : '' }}">
            <svg class="nav-icon" viewBox="0 0 24 24"><path d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
            Kategori
        </a>

        <span class="nav-label">Analitik</span>

        <a href="{{ route('reports.index') }}" class="nav-item {{ request()->routeIs('reports.*') ? 'active' : '' }}">
            <svg class="nav-icon" viewBox="0 0 24 24"><path d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
            Laporan & Statistik
        </a>
    </nav>

    <div class="sidebar-footer">
        <div class="sidebar-user">
            <div class="avatar">AD</div>
            <div>
                <div class="user-name">Admin Kasir</div>
                <div class="user-role">Administrator</div>
            </div>
        </div>
    </div>
</aside>

<!-- ═══════════════ MAIN ═══════════════ -->
<div class="main-wrap">
    <header class="topbar">
        <div class="breadcrumb">
            <a href="{{ route('dashboard') }}">Beranda</a>
            @hasSection('breadcrumb')
                <span class="breadcrumb-sep">›</span>
                <span class="breadcrumb-current">@yield('breadcrumb')</span>
            @endif
        </div>
        <div class="topbar-right">
            <div class="date-chip">
                <svg style="width:13px;height:13px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                {{ now()->locale('id')->translatedFormat('d F Y') }}
            </div>
        </div>
    </header>

    <main class="page-content">
        @if(session('success'))
        <div class="alert alert-success">
            <svg fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            {{ session('success') }}
        </div>
        @endif
        @if(session('error'))
        <div class="alert alert-danger">
            <svg fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
            {{ session('error') }}
        </div>
        @endif

        @yield('content')
    </main>
</div>

<!-- Toast container -->
<div class="toasts" id="toasts"></div>

<script>
function showToast(msg, type='success'){
    const c=document.getElementById('toasts');
    const t=document.createElement('div');
    t.className=`toast t-${type}`;
    const icons={success:'<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>',error:'<path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>'};
    t.innerHTML=`<svg style="width:16px;height:16px;flex-shrink:0" fill="currentColor" viewBox="0 0 20 20">${icons[type]||icons.success}</svg>${msg}`;
    c.appendChild(t);
    setTimeout(()=>{t.style.animation='tIn .25s reverse';setTimeout(()=>t.remove(),250)},3000);
}
function fmt(n){return'Rp '+new Intl.NumberFormat('id-ID').format(n)}
function openModal(id){document.getElementById(id).classList.add('open')}
function closeModal(id){document.getElementById(id).classList.remove('open')}
document.addEventListener('keydown',e=>{if(e.key==='Escape')document.querySelectorAll('.modal-ov.open').forEach(m=>m.classList.remove('open'))});
</script>
@stack('scripts')
</body>
</html>
