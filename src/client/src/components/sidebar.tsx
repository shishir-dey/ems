import React from "react";
import { cn } from "../misc/utils";

interface SidebarItem {
  id: string;
  label: string;
  icon?: React.ComponentType<{ className?: string }>;
}

interface SidebarProps {
  className?: string;
  items: SidebarItem[];
  activeItem: string;
  onItemClick: (id: string) => void;
}

export function Sidebar({
  className,
  items,
  activeItem,
  onItemClick,
}: SidebarProps) {
  return (
    <div className={cn("flex flex-col h-full bg-card border-r", className)}>
      <div className="p-6 border-b">
        {/* Empty header space where EMS used to be */}
      </div>
      <nav className="flex-1 px-3 pt-4">
        <div className="space-y-1">
          {items.map((item) => (
            <button
              key={item.id}
              onClick={() => onItemClick(item.id)}
              className={cn(
                "flex items-center gap-3 w-full rounded-md px-3 py-2 text-sm font-medium transition-colors",
                activeItem === item.id
                  ? "bg-accent text-accent-foreground"
                  : "text-muted-foreground hover:bg-accent/50 hover:text-accent-foreground",
              )}
            >
              {item.icon && <item.icon className="h-4 w-4" />}
              {item.label}
            </button>
          ))}
        </div>
      </nav>
      <div className="p-4 mt-auto border-t text-center">
        <p className="text-xs text-muted-foreground">&copy; 2025 Shishir Dey</p>
      </div>
    </div>
  );
}
