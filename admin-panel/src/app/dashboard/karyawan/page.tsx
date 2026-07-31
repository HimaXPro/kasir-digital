'use client';

import { useState } from 'react';
import { createEmployeeAccount } from './actions';

export default function KelolaKaryawanPage() {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [isError, setIsError] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');

    const formData = new FormData(e.currentTarget);
    const result = await createEmployeeAccount(formData);

    setIsError(!result.success);
    setMessage(result.message);
    setLoading(false);

    if (result.success) {
      (e.target as HTMLFormElement).reset();
    }
  };

  return (
    <div>
      <h1 style={{fontSize: '28px', fontWeight: 'bold', marginBottom: '8px'}}>Kelola Karyawan</h1>
      <p style={{color: 'var(--text-muted)', marginBottom: '32px'}}>Tambah dan atur akun staf (Kasir/Manager) untuk cabang Anda.</p>
      
      <div className="card" style={{maxWidth: '600px'}}>
        <h2 style={{fontSize: '18px', fontWeight: 'bold', marginBottom: '24px'}}>Tambah Akun Baru</h2>
        
        {message && (
          <div style={{
            padding: '12px', 
            marginBottom: '20px', 
            borderRadius: '8px', 
            backgroundColor: isError ? 'rgba(255,0,0,0.1)' : 'rgba(0,255,0,0.1)',
            color: isError ? 'var(--danger)' : 'var(--accent)',
            border: `1px solid ${isError ? 'rgba(255,0,0,0.2)' : 'rgba(0,255,0,0.2)'}`
          }}>
            {message}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Nama Karyawan</label>
            <input type="text" name="name" className="input-field" placeholder="Budi Santoso" required />
          </div>

          <div>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Email Login</label>
            <input type="email" name="email" className="input-field" placeholder="kasir@toko.com" required />
          </div>

          <div>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Password</label>
            <input type="password" name="password" className="input-field" placeholder="Minimal 6 karakter" required minLength={6} />
          </div>

          <div>
            <label style={{display: 'block', marginBottom: '8px', fontWeight: '600', fontSize: '13px'}}>Peran (Role)</label>
            <select name="role" className="input-field" required>
              <option value="kasir">Kasir</option>
              <option value="manager">Manager</option>
            </select>
          </div>

          <button type="submit" className="btn-primary" disabled={loading} style={{marginTop: '12px'}}>
            {loading ? 'Memproses...' : 'Buat Akun Karyawan'}
          </button>
        </form>
      </div>
    </div>
  );
}
