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
          <button style={{
            width: '100%', 
            background: 'var(--danger)', 
            color: 'white', 
            border: 'none', 
            padding: '12px', 
            borderRadius: '8px', 
            cursor: 'pointer',
            fontWeight: 'bold',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px'
          }} onClick={() => {
            auth.signOut().then(() => {
              window.location.href = '/login';
            });
          }}>
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
            Keluar Akses
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className={styles.mainContent}>
        {children}
      </main>
      
    </div>
  );
}
