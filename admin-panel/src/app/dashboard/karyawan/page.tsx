'use client';

import { useState, useEffect } from 'react';
import { db } from '@/lib/firebase';
import { collection, query, getDocs, doc, onSnapshot, setDoc } from 'firebase/firestore';

const LockIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
  </svg>
);

const EyeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
    <circle cx="12" cy="12" r="3"></circle>
  </svg>
);

const EyeOffIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
    <line x1="1" y1="1" x2="23" y2="23"></line>
  </svg>
);

const ShieldIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
  </svg>
);

interface BranchInfo {
  id: string;
  name: string;
  provinceId: string;
  cityId: string;
}

export default function ManajemenPinPage() {
  const [loading, setLoading] = useState(true);
  const [branches, setBranches] = useState<BranchInfo[]>([]);
  const [selectedBranch, setSelectedBranch] = useState<BranchInfo | null>(null);
  
  const [pins, setPins] = useState({
    pin_kasir: '',
    pin_manager: '',
    pin_owner: ''
  });
  
  const [showPins, setShowPins] = useState({
    kasir: false,
    manager: false,
    owner: false
  });
  
  const [isSaving, setIsSaving] = useState({ kasir: false, manager: false, owner: false });
  const [saveMessage, setSaveMessage] = useState({ text: '', type: '' });

  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const snap = await getDocs(query(collection(db, 'branches')));
        const branchesData: BranchInfo[] = [];
        snap.forEach((doc) => {
          branchesData.push({ id: doc.id, ...doc.data() } as BranchInfo);
        });
        setBranches(branchesData);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    fetchBranches();
  }, []);

  useEffect(() => {
    // Reset inputs whenever selected branch changes
    setPins({ pin_kasir: '', pin_manager: '', pin_owner: '' });
  }, [selectedBranch]);

  const handleSave = async (role: 'kasir' | 'manager' | 'owner') => {
    if (!selectedBranch) return;

    setIsSaving(prev => ({ ...prev, [role]: true }));
    setSaveMessage({ text: '', type: '' });

    const pinKey = `pin_${role}` as keyof typeof pins;
    const pinValue = pins[pinKey];

    if (pinValue.length !== 6) {
      setSaveMessage({ text: `PIN ${role} harus 6 digit.`, type: 'error' });
      setIsSaving(prev => ({ ...prev, [role]: false }));
      return;
    }

    try {
      const pinDocRef = doc(db, 'provinces', selectedBranch.provinceId, 'cities', selectedBranch.id, 'settings', 'store_pins');
      await setDoc(pinDocRef, { [pinKey]: pinValue }, { merge: true });
      setSaveMessage({ text: `PIN ${role} untuk ${selectedBranch.name} berhasil diperbarui!`, type: 'success' });
    } catch (error: any) {
      setSaveMessage({ text: `Gagal menyimpan: ` + error.message, type: 'error' });
    } finally {
      setIsSaving(prev => ({ ...prev, [role]: false }));
      setTimeout(() => setSaveMessage({ text: '', type: '' }), 4000);
    }
  };

  const toggleVisibility = (role: 'kasir' | 'manager' | 'owner') => {
    setShowPins(prev => ({ ...prev, [role]: !prev[role] }));
  };

  if (loading) return <div style={{padding: '40px', color: 'var(--text-muted)'}}>Memuat data cabang...</div>;

  const renderPinSection = (role: 'kasir' | 'manager' | 'owner', label: string) => (
    <div style={{ marginBottom: '24px' }}>
      <label style={{ display: 'block', color: '#94a3b8', fontSize: '14px', fontWeight: '600', marginBottom: '8px', textTransform: 'capitalize' }}>
        {label}
      </label>
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        background: '#0f172a', 
        borderRadius: '12px',
        border: '1px solid #1e293b',
        padding: '0 16px',
        marginBottom: '16px'
      }}>
        <div style={{ color: '#64748b', display: 'flex', alignItems: 'center' }}>
          <LockIcon />
        </div>
        <input 
          type={showPins[role] ? "text" : "password"}
          value={pins[`pin_${role}`]}
          onChange={(e) => setPins({...pins, [`pin_${role}`]: e.target.value.replace(/\D/g, '')})}
          maxLength={6}
          placeholder={selectedBranch ? "Ketik 6 digit PIN baru..." : ""}
          style={{
            flex: 1,
            background: 'transparent',
            border: 'none',
            color: '#f8fafc',
            padding: '16px 16px',
            fontSize: '15px',
            letterSpacing: (pins[`pin_${role}`] && !showPins[role]) ? '4px' : 'normal',
            outline: 'none',
            fontFamily: (pins[`pin_${role}`] && !showPins[role]) ? 'monospace' : 'inherit'
          }}
          disabled={!selectedBranch}
        />
        <button 
          onClick={() => toggleVisibility(role)}
          style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '8px' }}
          disabled={!selectedBranch}
        >
          {showPins[role] ? <EyeIcon /> : <EyeOffIcon />}
        </button>
      </div>
      <button 
        onClick={() => handleSave(role)}
        disabled={isSaving[role] || !selectedBranch}
        style={{
          width: '100%',
          background: '#f472b6',
          color: '#ffffff',
          border: 'none',
          borderRadius: '12px',
          padding: '14px',
          fontSize: '16px',
          fontWeight: '600',
          cursor: (isSaving[role] || !selectedBranch) ? 'not-allowed' : 'pointer',
          opacity: (isSaving[role] || !selectedBranch) ? 0.7 : 1,
          transition: 'background 0.2s, transform 0.1s',
          boxShadow: '0 4px 14px 0 rgba(244, 114, 182, 0.39)'
        }}
      >
        {isSaving[role] ? 'Menyimpan...' : `Simpan ${label}`}
      </button>
    </div>
  );

  return (
    <div style={{ paddingBottom: '60px' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{fontSize: '28px', fontWeight: 'bold', color: 'var(--text-main)', marginBottom: '8px'}}>Kendali PIN Pusat</h1>
        <p style={{color: 'var(--text-muted)'}}>Ubah PIN akses mesin kasir untuk seluruh cabang Anda dari jarak jauh.</p>
      </div>

      {saveMessage.text && (
        <div style={{
          padding: '16px', marginBottom: '24px', borderRadius: '12px', fontSize: '14px',
          background: saveMessage.type === 'error' ? '#fecdd3' : '#bbf7d0',
          color: saveMessage.type === 'error' ? '#881337' : '#14532d',
          fontWeight: '500', display: 'flex', alignItems: 'center', gap: '8px'
        }}>
          {saveMessage.type === 'success' ? '✓ ' : '⚠ '}
          {saveMessage.text}
        </div>
      )}

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', 
        gap: '32px',
        alignItems: 'start'
      }}>
        
        {/* Left Column: Branch Selector & Info */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          <div className="card" style={{ border: '1px solid var(--primary)', background: 'linear-gradient(to bottom right, var(--surface), rgba(244, 114, 182, 0.05))' }}>
            <label style={{ display: 'block', fontWeight: '600', marginBottom: '12px', color: 'var(--text-main)', fontSize: '15px' }}>
              Pilih Cabang Target:
            </label>
            <select 
              className="input-field" 
              style={{ width: '100%', padding: '14px', borderRadius: '10px', border: '1px solid var(--surface-border)', background: 'var(--bg-color)', fontSize: '15px', fontWeight: '500', cursor: 'pointer' }}
              value={selectedBranch?.id || ''}
              onChange={(e) => {
                const b = branches.find(x => x.id === e.target.value);
                setSelectedBranch(b || null);
              }}
            >
              <option value="">-- Pilih Cabang --</option>
              {branches.map(b => (
                <option key={b.id} value={b.id}>{b.name} ({b.cityId})</option>
              ))}
            </select>
            {!selectedBranch && (
              <p style={{ color: 'var(--danger)', fontSize: '13px', marginTop: '12px', fontWeight: '500' }}>
                * Silakan pilih cabang terlebih dahulu untuk membuka brankas PIN.
              </p>
            )}
          </div>

          <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '40px 24px' }}>
            <div style={{ background: 'rgba(244, 114, 182, 0.1)', padding: '20px', borderRadius: '50%', marginBottom: '20px' }}>
              <ShieldIcon />
            </div>
            <h3 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '12px' }}>Keamanan Tersentralisasi</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', lineHeight: '1.6' }}>
              Sebagai Superadmin, perubahan PIN yang Anda lakukan di sini akan langsung berlaku di mesin kasir cabang yang bersangkutan secara real-time.
            </p>
          </div>

        </div>

        {/* Right Column: The Vault */}
        <div>
          <div style={{ 
            background: '#1e293b', 
            padding: '32px 24px', 
            borderRadius: '24px', 
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            {/* Overlay if no branch selected */}
            {!selectedBranch && (
              <div style={{
                position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
                background: 'rgba(15, 23, 42, 0.8)',
                backdropFilter: 'blur(4px)',
                zIndex: 10,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexDirection: 'column',
                color: 'white'
              }}>
                <LockIcon />
                <span style={{ marginTop: '12px', fontWeight: '600' }}>Brankas Terkunci</span>
              </div>
            )}

            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '32px' }}>
              <div style={{ width: '8px', height: '32px', background: '#f472b6', borderRadius: '4px' }}></div>
              <h2 style={{ color: 'white', fontSize: '20px', fontWeight: 'bold', margin: 0 }}>
                {selectedBranch ? `Brankas: ${selectedBranch.name}` : 'Brankas Cabang'}
              </h2>
            </div>

            {renderPinSection('kasir', 'PIN Kasir')}
            <div style={{ height: '1px', background: '#334155', margin: '24px 0' }}></div>
            {renderPinSection('manager', 'PIN Manager')}
            <div style={{ height: '1px', background: '#334155', margin: '24px 0' }}></div>
            {renderPinSection('owner', 'PIN Owner')}
          </div>
        </div>

      </div>
    </div>
  );
}
