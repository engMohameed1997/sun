import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';
import './StatCard.css';

const StatCard = ({ title, value, unit, icon, trend, trendValue, color = 'gold' }) => {
  // If unit wasn't passed separately, split value if space present (e.g. "45,400,000 د.ع")
  let displayValue = value;
  let displayUnit = unit;

  if (!displayUnit && typeof value === 'string' && value.includes(' ')) {
    const parts = value.split(' ');
    displayValue = parts[0];
    displayUnit = parts.slice(1).join(' ');
  }

  return (
    <div className={`stat-card-v2 card-color-${color}`}>
      <div className="stat-header-v2">
        <h3 className="stat-title-v2">{title}</h3>
        <div className="stat-icon-wrapper-v2">
          {icon}
        </div>
      </div>

      <div className="stat-body-v2">
        <span className="stat-value-num">{displayValue}</span>
        {displayUnit && <span className="stat-unit-tag">{displayUnit}</span>}
      </div>

      {trend && (
        <div className="stat-footer-v2">
          <span className={`trend-badge ${trend}`}>
            {trend === 'up' ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
            {trendValue}
          </span>
          <span className="trend-text">مقارنة بالشهر الماضي</span>
        </div>
      )}
    </div>
  );
};

export default StatCard;
