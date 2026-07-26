import React from 'react';

export const CardSkeleton = () => (
  <div className="skeleton rounded-xl h-32 w-full mb-4"></div>
);

export const TableSkeleton = ({ rows = 5, cols = 4 }) => (
  <div className="w-full border rounded-xl overflow-hidden bg-white">
    <div className="flex border-b bg-gray-50 p-4">
      {Array(cols).fill(0).map((_, i) => (
        <div key={`th-${i}`} className="skeleton h-4 flex-1 mx-2 rounded"></div>
      ))}
    </div>
    {Array(rows).fill(0).map((_, r) => (
      <div key={`tr-${r}`} className="flex border-b p-4">
        {Array(cols).fill(0).map((_, c) => (
          <div key={`td-${r}-${c}`} className="skeleton h-4 flex-1 mx-2 rounded"></div>
        ))}
      </div>
    ))}
  </div>
);
