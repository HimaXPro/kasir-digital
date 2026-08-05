'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import styles from './layout.module.css';
import { Inter } from 'next/font/google';
import { auth, db } from '@/lib/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

const inter = Inter({ subsets: ['latin'] });

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [title, setTitle] = useState('Memuat...');
  const [loading, setLoading] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (user) => {
      if (user) {
        setTitle('Superadmin');
        setLoading(false);
      } else {
        // Redirect to login if user is not authenticated
        window.location.href = '/login';
      }
    });
    return () => unsubscribe();
  }, []);

  if (loading) {
    return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat antarmuka...</div>;
  }

  return (
    <div className={`${styles.dashboardContainer} ${inter.className}`}>
      
      {/* Mobile Topbar */}
      <div className={styles.mobileTopbar}>
        <div className={styles.logoMobile}>
          <h2>Kasir Digital</h2>
        </div>
        <button 
          className={styles.menuToggle} 
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
        >
          ☰
        </button>
      </div>

      {/* Overlay for mobile sidebar */}
      {isMobileMenuOpen && (
        <div 
          className={styles.mobileOverlay} 
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`${styles.sidebar} ${isMobileMenuOpen ? styles.sidebarOpen : ''}`}>
        <div className={styles.logo}>
          <h2>Kasir Digital</h2>
          <span className={styles.badge}>{title}</span>
        </div>
        
        <nav className={styles.nav}>
          <Link href="/dashboard" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
            <span className={styles.icon}>📊</span>
            Ringkasan
          </Link>
          <Link href="/dashboard/karyawan" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
            <span className={styles.icon}>👥</span>
            Manajemen PIN
          </Link>
          <Link href="/dashboard/cabang" className={styles.navItem} onClick={() => setIsMobileMenuOpen(false)}>
            <span className={styles.icon}>🏬</span>
            Manajemen Cabang
          </Link>
        </nav>
        
        <div className={styles.logoutBtn} style={{ paddingBottom: '24px' }}>
          <button 
            style={{
              width: '100%', 
              background: 'var(--danger)', 
              color: 'white', 
              border: 'none', 
              cursor: 'pointer',
              fontSize: '15px',
              padding: '12px 16px',
              borderRadius: '8px',
              fontWeight: 'bold',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'flex-start',
              gap: '12px'
            }} onClick={() => setIsLogoutModalOpen(true)}>
            <span className={styles.icon} style={{ display: 'flex', alignItems: 'center' }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
            </span>
            Keluar Akses
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className={styles.mainContent}>
        {children}
      </main>
      
      {/* Custom Logout Modal */}
      {isLogoutModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(5px)', zIndex: 1000,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div className="card" style={{ width: '90%', maxWidth: '400px', textAlign: 'center', padding: '32px 24px', animation: 'fadeIn 0.2s ease-out' }}>
            <div style={{ background: '#fef2f2', width: '64px', height: '64px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
            </div>
            <h2 style={{fontSize: '20px', fontWeight: 'bold', marginBottom: '12px', color: 'var(--text-main)'}}>Keluar dari Sistem?</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: '28px', fontSize: '14px', lineHeight: '1.5' }}>
              Anda harus masuk (login) kembali untuk mengakses dashboard Admin Panel ini.
            </p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
              <button 
                onClick={() => setIsLogoutModalOpen(false)}
                style={{ flex: 1, padding: '12px', background: 'transparent', border: '1px solid var(--surface-border)', color: 'var(--text-muted)', borderRadius: '8px', cursor: 'pointer', fontWeight: '600' }}
              >
                Batal
              </button>
              <button 
                onClick={() => {
                  auth.signOut().then(() => {
                    window.location.href = '/login';
                  });
                }}
                style={{ flex: 1, padding: '12px', background: 'var(--danger)', border: 'none', color: 'white', borderRadius: '8px', cursor: 'pointer', fontWeight: '600' }}
              >
                Ya, Keluar
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
