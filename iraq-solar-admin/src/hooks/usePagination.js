import { useState } from 'react';

export const usePagination = (initialPage = 1, initialPerPage = 10) => {
  const [page, setPage] = useState(initialPage);
  const [perPage, setPerPage] = useState(initialPerPage);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);

  const handlePageChange = (newPage) => {
    if (newPage >= 1 && newPage <= totalPages) {
      setPage(newPage);
    }
  };

  return {
    page,
    perPage,
    totalPages,
    totalItems,
    setPage: handlePageChange,
    setPerPage,
    setTotalPages,
    setTotalItems,
  };
};
