import React, { useCallback, useState } from 'react';
import { UploadCloud, X, Image as ImageIcon } from 'lucide-react';
import toast from 'react-hot-toast';

const ImageUploader = ({ value, onChange, onUploadError }) => {
  const [isDragging, setIsDragging] = useState(false);
  const [preview, setPreview] = useState(value);

  const handleDrag = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setIsDragging(true);
    } else if (e.type === 'dragleave') {
      setIsDragging(false);
    }
  }, []);

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    
    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      handleFile(files[0]);
    }
  }, []);

  const handleChange = (e) => {
    e.preventDefault();
    if (e.target.files && e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  };

  const handleFile = (file) => {
    if (!file.type.startsWith('image/')) {
      toast.error('يرجى رفع ملف صورة صحيح');
      return;
    }
    
    // Create preview
    const objectUrl = URL.createObjectURL(file);
    setPreview(objectUrl);
    onChange(file);
  };

  const handleRemove = (e) => {
    e.stopPropagation();
    setPreview(null);
    onChange(null);
  };

  return (
    <div 
      className={`relative border-2 border-dashed rounded-xl p-6 transition-all text-center cursor-pointer 
        ${isDragging ? 'border-primary-gold bg-amber-50/50' : 'border-gray-300 hover:bg-gray-50'}
        ${preview ? 'p-2' : ''}`}
      onDragEnter={handleDrag}
      onDragLeave={handleDrag}
      onDragOver={handleDrag}
      onDrop={handleDrop}
      onClick={() => document.getElementById('file-upload').click()}
    >
      <input 
        id="file-upload" 
        type="file" 
        accept="image/*" 
        className="hidden" 
        onChange={handleChange}
      />
      
      {preview ? (
        <div className="relative group rounded-lg overflow-hidden h-48">
          <img src={preview} alt="Preview" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
            <button 
              onClick={handleRemove}
              className="p-2 bg-red-600 text-white rounded-full hover:bg-red-700 transition-colors"
            >
              <X size={20} />
            </button>
          </div>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-2 py-6">
          <div className="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mb-2">
            <UploadCloud size={32} />
          </div>
          <p className="font-medium text-gray-700">اضغط أو اسحب الصورة هنا</p>
          <p className="text-sm text-gray-500">PNG, JPG, WEBP حتى 5MB</p>
        </div>
      )}
    </div>
  );
};

export default ImageUploader;
