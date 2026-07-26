import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Package } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { getProducts, deleteProduct } from '../../api/adminApi';
import { PRODUCT_TYPES } from '../../utils/constants';
import DataTable from '../../components/shared/DataTable';
import SearchFilterBar from '../../components/shared/SearchFilterBar';
import StatusBadge from '../../components/shared/StatusBadge';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import EditProductModal from './EditProductModal';

const ProductsPage = () => {
  const [products, setProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filters, setFilters] = useState({ search: '', type: 'all' });
  
  const [deleteDialog, setDeleteDialog] = useState({ isOpen: false, id: null });
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  const fetchProducts = async () => {
    setIsLoading(true);
    try {
      const response = await getProducts({ 
        search: filters.search, 
        type: filters.type !== 'all' ? filters.type : undefined 
      });
      const data = response.data?.data?.products || response.data?.data || response.data || [];
      setProducts(data);
    } catch (error) {
      console.error('Error fetching products:', error);
      toast.error('حدث خطأ أثناء جلب المنتجات');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, [filters]);

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const handleDeleteClick = (id) => {
    setDeleteDialog({ isOpen: true, id });
  };

  const confirmDelete = async () => {
    try {
      await deleteProduct(deleteDialog.id);
      toast.success('تم حذف المنتج بنجاح');
      fetchProducts();
    } catch (error) {
      console.error('Error deleting product:', error);
      toast.error('حدث خطأ أثناء حذف المنتج');
    } finally {
      setDeleteDialog({ isOpen: false, id: null });
    }
  };

  const handleEditClick = (product) => {
    setSelectedProduct(product);
    setIsEditModalOpen(true);
  };

  const handleEditModalClose = () => {
    setIsEditModalOpen(false);
    setSelectedProduct(null);
  };

  const handleEditSave = () => {
    setIsEditModalOpen(false);
    setSelectedProduct(null);
    fetchProducts();
  };

  const filterOptions = [
    { value: 'all', label: 'جميع الأنواع' },
    ...Object.entries(PRODUCT_TYPES).map(([key, label]) => ({ value: key, label }))
  ];

  const columns = [
    {
      header: 'المنتج',
      accessor: 'name',
      render: (product) => (
        <div className="flex items-center">
          <div className="w-10 h-10 rounded-lg bg-primary-gold/10 flex items-center justify-center text-primary-gold ml-3 flex-shrink-0">
            <Package size={20} />
          </div>
          <div>
            <p className="font-semibold text-white">{product.name}</p>
            <p className="text-xs text-white/60">
              {product.brand} {product.model ? `- ${product.model}` : ''} {product.sku ? `(SKU: ${product.sku})` : ''}
            </p>
          </div>
        </div>
      )
    },
    {
      header: 'النوع',
      accessor: 'type',
      render: (product) => PRODUCT_TYPES[product.type] || product.type
    },
    {
      header: 'السعر (USD)',
      accessor: 'price_usd',
      render: (product) => <span className="font-medium">${Number(product.price_usd).toFixed(2)}</span>
    },
    {
      header: 'المخزون',
      accessor: 'stock_quantity',
      render: (product) => (
        <span className={`font-semibold ${product.stock_quantity < 10 ? 'text-red-400' : 'text-green-400'}`}>
          {product.stock_quantity}
        </span>
      )
    },
    {
      header: 'الحالة',
      accessor: 'is_available',
      render: (product) => (
        <StatusBadge 
          status={product.is_available ? 'active' : 'inactive'} 
          text={product.is_available ? 'متاح' : 'مخفي'} 
        />
      )
    },
    {
      header: 'الإجراءات',
      accessor: 'id',
      render: (product) => (
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleEditClick(product)}
            className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white transition-colors"
            title="تعديل"
          >
            <Edit size={18} />
          </button>
          <button 
            onClick={() => handleDeleteClick(product.id)}
            className="p-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 transition-colors"
            title="حذف"
          >
            <Trash2 size={18} />
          </button>
        </div>
      )
    }
  ];

  return (
    <div className="space-y-6 animate-slide-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">إدارة المنتجات</h1>
          <p className="text-white/60">عرض وتعديل وحذف منتجات المتجر</p>
        </div>
        
        <button className="btn btn-primary flex items-center gap-2">
          <Plus size={20} />
          <span>إضافة منتج جديد</span>
        </button>
      </div>

      <div className="glass rounded-xl p-4 md:p-6">
        <SearchFilterBar 
          onSearch={(val) => handleFilterChange('search', val)}
          onFilter={(val) => handleFilterChange('type', val)}
          filterOptions={filterOptions}
          searchPlaceholder="البحث عن منتج..."
        />
        
        <div className="mt-6">
          <DataTable 
            columns={columns} 
            data={products} 
            isLoading={isLoading} 
            emptyMessage="لا توجد منتجات مطابقة للبحث"
          />
        </div>
      </div>

      <ConfirmDialog 
        isOpen={deleteDialog.isOpen}
        title="تأكيد الحذف"
        message="هل أنت متأكد من رغبتك في حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء."
        onConfirm={confirmDelete}
        onCancel={() => setDeleteDialog({ isOpen: false, id: null })}
      />

      <EditProductModal 
        isOpen={isEditModalOpen}
        product={selectedProduct}
        onClose={handleEditModalClose}
        onSave={handleEditSave}
      />
    </div>
  );
};

export default ProductsPage;
