import React, { useEffect, useMemo, useRef, useState } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Locale } from '../../store/locale';

interface BenchRole {
  id: number;
  name: string;
  canUse: boolean;
  canManage: boolean;
  canMove: boolean;
  canPack: boolean;
  members?: { identifier: string; name: string }[];
}

interface BenchPermissionsData {
  benchId: string;
  owner: {
    name: string;
    identifier: string;
    online: boolean;
    serverId: number;
  };
  roles: BenchRole[];
  onlinePlayers?: { source: number; identifier: string; name: string }[];
  playerPermissions?: {
    isOwner?: boolean;
    canManage?: boolean;
  };
  password?: string;
}

interface BenchPermissionsProps {
  embedded?: boolean;
  active?: boolean;
  benchId?: string;
  onClose?: () => void;
  initialTab?: BenchPermissionsTab;
}

type BenchPermissionsTab = 'roles' | 'settings' | 'members' | 'global';

const translate = (key: string, fallback: string, replacements?: Record<string, string | number>) => {
  let value = Locale[key] || fallback;

  if (replacements) {
    Object.entries(replacements).forEach(([replacementKey, replacementValue]) => {
      value = value.replace(new RegExp(`\\{${replacementKey}\\}`, 'g'), String(replacementValue));
    });
  }

  return value;
};

const BenchPermissions: React.FC<BenchPermissionsProps> = ({
  embedded = false,
  active = true,
  benchId,
  onClose,
  initialTab = 'roles',
}) => {
  const [visible, setVisible] = useState(false);
  const [data, setData] = useState<BenchPermissionsData | null>(null);
  const [selectedRole, setSelectedRole] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<BenchPermissionsTab>('roles');
  const [memberPickerOpen, setMemberPickerOpen] = useState(false);
  const [memberRolePicker, setMemberRolePicker] = useState<string | null>(null);
  const [editingRole, setEditingRole] = useState<Partial<BenchRole> | null>(null);
  const [confirmation, setConfirmation] = useState<{ title: string; message: string; onConfirm: () => void } | null>(
    null
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [password, setPasswordState] = useState('');
  const memberPickerRef = useRef<HTMLDivElement | null>(null);
  const memberRolePickerRef = useRef<HTMLDivElement | null>(null);

  useNuiEvent<BenchPermissionsData>('openBenchPermissions', (payload) => {
    const roles = Array.isArray(payload.roles) ? payload.roles : [];
    setData({ ...payload, roles });
    setVisible(true);
    setLoading(false);
    setLoadError(null);
    setIsSubmitting(false);
    setPasswordState(payload.password || '');
    setSelectedRole((currentRole) => {
      if (currentRole && roles.some((role) => role.id === currentRole)) return currentRole;
      return roles[0]?.id ?? null;
    });
  });

  useEffect(() => {
    if (data && selectedRole) {
      const roleExists = data.roles.some((role) => role.id === selectedRole);
      if (!roleExists) {
        setSelectedRole(data.roles[0]?.id ?? null);
      }
    }
  }, [data, selectedRole]);

  useEffect(() => {
    setActiveTab(initialTab);
  }, [benchId, initialTab]);

  useEffect(() => {
    if (!embedded) return;

    if (!active) {
      setEditingRole(null);
      setConfirmation(null);
      setLoading(false);
      setLoadError(null);
      return;
    }

    if (!benchId) {
      setLoadError(translate('bench_permissions_not_found', 'Bench not found'));
      return;
    }

    if (data?.benchId === benchId) return;

    setLoading(true);
    setLoadError(null);

    const openEvent = 'benchPermissions:open';
    fetchNui<{ ok?: boolean; error?: string }>(openEvent, { benchId })
      .then((response) => {
        if (!response?.ok) {
          setLoading(false);
          setLoadError(response?.error || translate('permissions_unable_to_load', 'Unable to load permissions.'));
        }
      })
      .catch(() => {
        setLoading(false);
        setLoadError(translate('permissions_unable_to_load', 'Unable to load permissions.'));
      });
  }, [embedded, active, benchId, data?.benchId]);

  useEffect(() => {
    if (activeTab === 'roles' || !data) return;

    if (!selectedRole || !data?.roles.some((role) => role.id === selectedRole)) {
      setActiveTab('roles');
    }
  }, [activeTab, data?.roles, selectedRole]);

  useEffect(() => {
    setMemberPickerOpen(false);
    setMemberRolePicker(null);
  }, [activeTab, benchId, selectedRole]);

  useEffect(() => {
    if (!memberPickerOpen && !memberRolePicker) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (!memberPickerRef.current?.contains(event.target as Node)) {
        setMemberPickerOpen(false);
      }

      if (!memberRolePickerRef.current?.contains(event.target as Node)) {
        setMemberRolePicker(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [memberPickerOpen, memberRolePicker]);

  const handleClose = () => {
    setVisible(false);
    setData(null);
    setSelectedRole(null);
    setEditingRole(null);
    setConfirmation(null);
    setLoading(false);
    setLoadError(null);
    setIsSubmitting(false);
    fetchNui('benchPermissions:close');
    onClose?.();
  };

  const handleUpdateRole = (role: Partial<BenchRole>) => {
    if (!role.id) return;

    fetchNui('benchPermissions:updateRole', {
      benchId: data?.benchId,
      roleId: role.id,
      name: role.name,
      permissions: {
        use: role.canUse,
        move: role.canMove,
        pack: role.canPack,
        manage: role.canManage,
      },
    });
  };

  const handleDeleteRole = (roleId: number) => {
    setConfirmation({
      title: t('permissions_delete_role', 'Delete Role'),
      message: t('permissions_delete_role_confirm', 'Are you sure you want to delete this role?'),
      onConfirm: () => {
        fetchNui('benchPermissions:deleteRole', {
          benchId: data?.benchId,
          roleId,
        });
        setConfirmation(null);
      },
    });
  };

  const handleSetMemberRole = (target: string | number, roleId: number | '') => {
    fetchNui('benchPermissions:setMemberRole', {
      benchId: data?.benchId,
      target,
      roleId: roleId === '' ? null : roleId,
    });
  };

  const handleSetPassword = () => {
    if (!data) return;
    fetchNui('benchPermissions:setPassword', {
      benchId: data.benchId,
      password: password,
    });
  };

  const allRoleMembers = useMemo(
    () => (data?.roles || []).flatMap((role) => (role.members || []).map((member) => ({ ...member, role: role.id }))),
    [data]
  );

  const selectedRoleData = useMemo(
    () => data?.roles?.find((role) => role.id === selectedRole) || null,
    [data, selectedRole]
  );

  const alternativeRoles = useMemo(
    () => (data?.roles || []).filter((role) => role.id !== selectedRoleData?.id),
    [data?.roles, selectedRoleData?.id]
  );

  const availableOnlinePlayers = useMemo(
    () =>
      (data?.onlinePlayers || []).filter(
        (player) =>
          player.identifier !== data?.owner?.identifier &&
          !allRoleMembers.find((member) => member.identifier === player.identifier)
      ),
    [allRoleMembers, data?.onlinePlayers, data?.owner?.identifier]
  );

  const isOwner = !!(data?.playerPermissions?.isOwner || data?.playerPermissions?.canManage);
  const shouldRender = embedded ? active : visible;
  const t = translate;
  const membersCountLabel = (count: number) => t('permissions_members_count', '{count} members', { count });
  const permissionItems = [
    {
      key: 'canUse',
      label: t('bench_permissions_use_bench', 'Use Bench'),
      desc: t('bench_permissions_use_bench_desc', 'Can open and use the bench'),
    },
    {
      key: 'canMove',
      label: t('bench_permissions_move_bench', 'Move Bench'),
      desc: t('bench_permissions_move_bench_desc', 'Can move the bench position'),
    },
    {
      key: 'canPack',
      label: t('bench_permissions_pack_bench', 'Pack Bench'),
      desc: t('bench_permissions_pack_bench_desc', 'Can pack the bench item'),
    },
    {
      key: 'canManage',
      label: t('bench_permissions_manage_bench', 'Manage Bench'),
      desc: t('bench_permissions_manage_bench_desc', 'Can edit roles and members'),
    },
  ] as const;

  if (!shouldRender) return null;

  const renderHeader = () => (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-3">
        <div style={{ filter: 'drop-shadow(0 0 6px rgba(var(--color-primary-rgb), 0.35))' }}>
          <div
            style={{
              width: 52,
              height: 52,
              backgroundColor: 'rgba(var(--color-primary-rgb), 0.25)',
              borderRadius: 6,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <div
              style={{
                width: 42,
                height: 42,
                backgroundColor: 'var(--color-primary)',
                borderRadius: 4,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <span
                className="material-symbols-outlined"
                style={{
                  fontSize: 20,
                  color: 'var(--ui-accent-foreground)',
                  fontVariationSettings: "'FILL' 1",
                }}
              >
                admin_panel_settings
              </span>
            </div>
          </div>
        </div>
        <div className="flex flex-col leading-tight mt-0.5">
          <p className="text-white font-bold text-xl tracking-wide uppercase">
            {t('bench_permissions_title', 'Bench Permissions')}
          </p>
          <div className="mt-1 flex items-center gap-2">
            <span className="text-[11px] font-semibold uppercase tracking-[0.14em] text-white/40">
              {t('permissions_owner', 'Owner')}
            </span>
            <span className="rounded-md border border-[rgba(var(--color-primary-rgb),0.24)] bg-[rgba(var(--color-primary-rgb),0.1)] px-2 py-0.5 text-[12px] font-semibold text-[var(--color-primary)]">
              {data?.owner?.name || t('permissions_unknown', 'Unknown')}
            </span>
          </div>
        </div>
      </div>

      {!embedded && (
        <button
          onClick={handleClose}
          className="w-9 h-9 rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] text-white/70 hover:text-white transition-colors"
        >
          <span className="material-symbols-outlined text-[20px]">close</span>
        </button>
      )}
    </div>
  );

  const renderEmptyState = (icon: string, title: string, description: string) => (
    <div className="flex h-full flex-col items-center justify-center text-center text-white/35">
      <span className="material-symbols-outlined text-[42px]">{icon}</span>
      <p className="mt-2 text-[16px] font-semibold text-white/70">{title}</p>
      <p className="mt-1 max-w-[240px] text-[12px] text-white/40">{description}</p>
    </div>
  );

  const renderNavigation = () => (
    <div className="mb-3 flex items-center gap-2 rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] p-1">
      {[
        { key: 'roles', label: t('permissions_roles', 'Roles'), icon: 'badge' },
        { key: 'settings', label: t('permissions_permissions', 'Permissions'), icon: 'tune' },
        { key: 'members', label: t('permissions_members', 'Members'), icon: 'groups' },
      ].map((tab) => {
        const isDisabled = tab.key !== 'roles' && !selectedRoleData;

        return (
          <button
            key={tab.key}
            onClick={() => !isDisabled && setActiveTab(tab.key as BenchPermissionsTab)}
            disabled={isDisabled}
            className={`flex h-[32px] flex-1 items-center justify-center gap-1 rounded-md text-[10px] font-bold uppercase tracking-[0.08em] transition-all ${
              activeTab === tab.key
                ? 'bg-[var(--color-primary)] text-[#131313]'
                : 'text-white/55 hover:bg-white/5 hover:text-white'
            } ${isDisabled ? 'cursor-not-allowed opacity-35 hover:bg-transparent hover:text-white/55' : ''}`}
          >
            <span className="material-symbols-outlined text-[15px]">{tab.icon}</span>
            <span>{tab.label}</span>
          </button>
        );
      })}
    </div>
  );

  const renderRoleOverview = () => {
    if (!data) {
      return renderEmptyState(
        'groups',
        t('bench_permissions_empty_title', 'No Bench Selected'),
        t('bench_permissions_empty_desc', 'Open a crafting bench to manage its permissions.')
      );
    }

    return (
      <div className="flex h-full flex-col overflow-hidden rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] p-2.5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8d8d8d]">
              {t('permissions_roles', 'Roles')}
            </p>
            <p className="mt-1 text-[11px] leading-4 text-[#A8A8A8]">
              {t('bench_permissions_roles_desc', 'Select a role to open its settings and manage access.')}
            </p>
          </div>
          <span className="rounded-md bg-black/25 px-2 py-1 text-[10px] font-bold uppercase text-white/45">
            {(data.roles || []).length}
          </span>
        </div>

        <div className="mt-3 flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto pr-1">
          {(data.roles || []).map((role) => (
            <button
              key={role.id}
              onClick={() => {
                setSelectedRole(role.id);
                setActiveTab('settings');
              }}
              className={`rounded-md border px-2.5 py-2.5 text-left transition-colors ${
                selectedRole === role.id
                  ? 'border-[rgba(var(--color-primary-rgb),0.4)] bg-[rgba(var(--color-primary-rgb),0.12)] text-[var(--color-primary)]'
                  : 'border-[rgba(135,135,135,0.15)] bg-transparent text-white/80 hover:border-[rgba(170,170,170,0.25)] hover:bg-white/5 hover:text-white'
              }`}
            >
              <div className="flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate text-[13px] font-semibold">{role.name}</p>
                  <p className="mt-1 text-[9px] uppercase tracking-[0.14em] text-white/35">
                    {membersCountLabel((role.members || []).length)}
                  </p>
                </div>
                <span className="material-symbols-outlined text-[16px] opacity-70">chevron_right</span>
              </div>
            </button>
          ))}
        </div>

        <div className="mt-3">
          {isOwner && (
            <button
              onClick={() =>
                setEditingRole({ name: '', canUse: true, canMove: false, canPack: false, canManage: false })
              }
              className="flex h-[38px] w-full items-center justify-center gap-2 rounded-md border border-dashed border-[rgba(135,135,135,0.2)] text-[11px] font-semibold text-white/60 transition-colors hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:text-[var(--color-primary)]"
            >
              <span className="material-symbols-outlined text-[15px]">add</span>
              <span>{t('permissions_create_role', 'Create Role')}</span>
            </button>
          )}
        </div>
      </div>
    );
  };

  const renderSelectedRoleHeader = (description: string, showActions = false) => {
    if (!selectedRoleData) return null;

    return (
      <div className="rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] p-2.5">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8d8d8d]">
                {t('permissions_selected_role', 'Selected Role')}
              </p>
              <h2 className="mt-1 text-[22px] font-bold uppercase tracking-wide text-white">{selectedRoleData.name}</h2>
              <p className="mt-1 text-[11px] leading-4 text-[#A8A8A8]">{description}</p>
            </div>
          </div>

          <div className="flex flex-col items-end gap-2">
            <div className="rounded-md border border-[rgba(var(--color-primary-rgb),0.24)] bg-[rgba(var(--color-primary-rgb),0.08)] px-2 py-0.5 text-[9px] font-bold uppercase tracking-[0.12em] text-[var(--color-primary)]">
              {membersCountLabel((selectedRoleData.members || []).length)}
            </div>

            {showActions && isOwner && (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setEditingRole(selectedRoleData)}
                  className="flex h-[30px] items-center gap-1.5 rounded-md border border-[rgba(135,135,135,0.18)] bg-black/25 px-2.5 text-[9px] font-semibold uppercase tracking-[0.08em] text-white/80 transition-colors hover:text-white"
                >
                  <i className="fas fa-pen text-[9px]"></i>
                  <span>{t('permissions_rename', 'Rename')}</span>
                </button>
                <button
                  onClick={() => handleDeleteRole(selectedRoleData.id)}
                  className="flex h-[30px] items-center gap-1.5 rounded-md border border-red-500/20 bg-red-500/10 px-2.5 text-[9px] font-semibold uppercase tracking-[0.08em] text-red-300 transition-colors hover:bg-red-500/15"
                >
                  <i className="fas fa-trash text-[9px]"></i>
                  <span>{t('permissions_delete', 'Delete')}</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  };

  const renderMemberRoleMenu = (identifier: string) => (
    <div className="absolute top-[calc(100%+8px)] left-0 z-20 w-[152px] overflow-hidden rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(40,40,40,0.96)_0%,rgba(28,28,28,0.88)_100%)] shadow-[0_10px_24px_rgba(0,0,0,0.28)]">
      <div className="max-h-[190px] overflow-y-auto p-1">
        {alternativeRoles.length === 0 ? (
          <div className="px-2.5 py-2.5 text-[11px] text-white/45">{t('permissions_no_roles', 'No roles')}</div>
        ) : (
          alternativeRoles.map((role) => (
            <button
              key={role.id}
              onClick={() => {
                handleSetMemberRole(identifier, role.id);
                setMemberRolePicker(null);
              }}
              className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left transition-colors hover:bg-[rgba(var(--color-primary-rgb),0.1)]"
            >
              <div className="min-w-0 pr-2">
                <p className="truncate whitespace-nowrap text-[10px] font-semibold text-white">{role.name}</p>
                <p className="mt-0.5 whitespace-nowrap text-[9px] text-white/35">
                  {membersCountLabel((role.members || []).length)}
                </p>
              </div>
              <span className="material-symbols-outlined text-[15px] text-[var(--color-primary)]">arrow_forward</span>
            </button>
          ))
        )}

        <div className="my-1 h-px bg-white/10" />

        <button
          onClick={() => {
            setConfirmation({
              title: t('permissions_remove_member', 'Remove Member'),
              message: t('permissions_remove_member_confirm', 'Remove this member from the selected role?'),
              onConfirm: () => {
                handleSetMemberRole(identifier, '');
                setMemberRolePicker(null);
                setConfirmation(null);
              },
            });
          }}
          className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left transition-colors hover:bg-red-500/10"
        >
          <span className="whitespace-nowrap text-[10px] font-semibold text-red-300">
            {t('permissions_remove_access', 'Remove access')}
          </span>
          <span className="material-symbols-outlined text-[15px] text-red-300">person_remove</span>
        </button>
      </div>
    </div>
  );

  const renderGlobalSettings = () => {
    if (!data) return null;

    return (
      <div className="flex h-full flex-col overflow-hidden rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] p-2.5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8d8d8d]">
              {t('bench_permissions_global_title', 'Bench Settings')}
            </p>
            <p className="mt-1 text-[11px] leading-4 text-[#A8A8A8]">
              {t('bench_permissions_global_desc', 'Manage global settings for this bench.')}
            </p>
          </div>
        </div>

        <div className="mt-4 flex flex-1 flex-col gap-4 overflow-y-auto pr-1">
          <div className="rounded-lg border border-[rgba(135,135,135,0.18)] bg-black/25 p-3">
            <p className="text-[10px] font-bold uppercase tracking-wider text-white/40">
              {t('bench_permissions_access_password', 'Access Password')}
            </p>
            <p className="mt-0.5 text-[11px] text-white/30">
              {t('bench_permissions_access_password_desc', 'Requires all players to enter this password to open the bench.')}
            </p>
            <div className="mt-3 flex items-center gap-2">
              <input
                type="text"
                placeholder={t('bench_permissions_no_password', 'No password set')}
                value={password}
                readOnly={!isOwner}
                onChange={(e) => setPasswordState(e.target.value)}
                className={`flex h-[38px] flex-1 items-center rounded-md border border-[rgba(135,135,135,0.18)] bg-black/20 px-3 text-[13px] text-white transition-colors focus:border-[rgba(var(--color-primary-rgb),0.35)] outline-none ${
                  !isOwner ? 'opacity-50 cursor-not-allowed' : ''
                }`}
              />
              {isOwner && (
                <button
                  onClick={handleSetPassword}
                  className="flex h-[38px] items-center gap-1.5 rounded-md bg-[var(--color-primary)] px-4 text-[11px] font-bold uppercase text-[#131313] transition-opacity hover:opacity-90"
                >
                  {t('permissions_save', 'Save')}
                </button>
              )}
            </div>
            <p className="mt-2 text-[10px] text-white/20 italic">
              {t('bench_permissions_disable_password_hint', 'Leave empty to disable password protection.')}
            </p>
          </div>
        </div>
      </div>
    );
  };

  const renderMainContent = () => {
    if (loading) {
      return renderEmptyState(
        'hourglass_top',
        t('permissions_loading', 'Loading Permissions'),
        t('bench_permissions_loading_desc', 'Fetching bench roles and member access.')
      );
    }

    if (loadError) {
      return renderEmptyState('lock', t('permissions_unavailable', 'Unavailable'), loadError);
    }

    if (!data) {
      return renderEmptyState(
        'groups',
        t('bench_permissions_empty_title', 'No Bench Selected'),
        t('bench_permissions_empty_desc', 'Open a crafting bench to manage its permissions.')
      );
    }

    if (activeTab === 'roles') {
      return renderRoleOverview();
    }

    if (activeTab === 'global') {
      return renderGlobalSettings();
    }

    if (!selectedRoleData) {
      return renderEmptyState(
        'group',
        t('permissions_select_role', 'Select A Role'),
        t('bench_permissions_select_role_desc', 'Open the Roles tab and choose a role to manage bench access.')
      );
    }

    return (
      <div className="flex h-full flex-col overflow-hidden">
        {activeTab === 'settings' ? (
          <>
            {renderSelectedRoleHeader(t('bench_permissions_role_access_desc', 'Configure permissions and bench access for this role.'), true)}
            <div className="mt-3 flex flex-1 flex-col gap-2.5 overflow-y-auto pr-1">
              {permissionItems.map((permission) => {
                const isEnabled = !!(selectedRoleData as any)[permission.key];

                return (
                  <div
                    key={permission.key}
                    className="rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-2.5 py-2.5"
                  >
                    <div className="flex items-center justify-between gap-4">
                      <div className="min-w-0 pr-3">
                        <p className="text-[13px] font-semibold text-white">{permission.label}</p>
                        <p className="mt-1 text-[10px] leading-4 text-white/40">{permission.desc}</p>
                      </div>

                      {isOwner ? (
                        <button
                          onClick={() =>
                            handleUpdateRole({
                              ...selectedRoleData,
                              [permission.key]: !isEnabled,
                            })
                          }
                          className={`relative h-6 w-11 flex-shrink-0 rounded-full transition-colors ${
                            isEnabled ? 'bg-[var(--color-primary-dark)]' : 'bg-white/10'
                          }`}
                        >
                          <div
                            className={`absolute top-1 h-4 w-4 rounded-full bg-white transition-all ${
                              isEnabled ? 'left-6' : 'left-1'
                            }`}
                          />
                        </button>
                      ) : (
                        <div
                          className={`flex-shrink-0 rounded-md px-2.5 py-1 text-[10px] font-bold uppercase ${
                            isEnabled
                              ? 'bg-[rgba(var(--color-primary-rgb),0.1)] text-[var(--color-primary)]'
                              : 'bg-white/5 text-white/40'
                          }`}
                        >
                          {isEnabled ? t('permissions_allowed', 'Allowed') : t('permissions_denied', 'Denied')}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        ) : (
          <>
            {renderSelectedRoleHeader(t('bench_permissions_assigned_members_desc', 'Manage assigned members for this role.'))}
            <div className="mt-3 flex flex-1 flex-col overflow-hidden rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] p-2.5">
              <div className="flex items-center justify-between">
                <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8d8d8d]">
                  {t('permissions_assigned_members', 'Assigned Members')}
                </p>
                <span className="text-[11px] font-semibold text-white/40">
                  {(Array.isArray(selectedRoleData.members) ? selectedRoleData.members : []).length}
                </span>
              </div>

              <div className="mt-3 flex flex-1 flex-col gap-2 overflow-y-auto pr-1">
                <div className="rounded-md border border-[rgba(var(--color-primary-rgb),0.18)] bg-[rgba(var(--color-primary-rgb),0.05)] px-2.5 py-2">
                  <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-white/40">
                    {t('bench_permissions_owner_card', 'Bench Owner')}
                  </p>
                  <div className="mt-2 flex items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate text-[12px] font-semibold text-white">
                        {data.owner?.name || t('permissions_unknown', 'Unknown')}
                      </p>
                      <p className="mt-0.5 text-[10px] uppercase text-[var(--color-primary)]">
                        {t('permissions_owner', 'Owner')}
                      </p>
                    </div>
                    <i className="fas fa-crown text-[11px] text-yellow-500"></i>
                  </div>
                </div>

                {(Array.isArray(selectedRoleData.members) ? selectedRoleData.members : []).length === 0 ? (
                  <div className="flex h-full flex-col items-center justify-center text-center text-white/35">
                    <span className="material-symbols-outlined text-[42px]">person_off</span>
                    <p className="mt-2 text-sm font-semibold text-white/55">
                      {t('permissions_no_members_assigned', 'No members assigned')}
                    </p>
                    <p className="mt-1 text-[12px] text-white/35">
                      {t('permissions_add_online_player_desc', 'Add an online player to this role from the selector below.')}
                    </p>
                  </div>
                ) : (
                  (Array.isArray(selectedRoleData.members) ? selectedRoleData.members : []).map((member) => (
                    <div
                      key={member.identifier}
                      className="flex items-center justify-between rounded-md border border-[rgba(135,135,135,0.15)] bg-transparent px-2.5 py-2 hover:bg-white/5 transition-colors"
                    >
                      <div className="min-w-0 pr-2">
                        <p className="truncate text-[12px] font-semibold text-white">{member.name}</p>
                        <p className="mt-0.5 truncate text-[10px] text-white/35">{member.identifier}</p>
                      </div>
                      {isOwner && (
                        <div className="flex items-center gap-2">
                          <div
                            className="relative"
                            ref={memberRolePicker === member.identifier ? memberRolePickerRef : undefined}
                          >
                            {memberRolePicker === member.identifier && renderMemberRoleMenu(member.identifier)}

                            <button
                              onClick={() =>
                                setMemberRolePicker((current) =>
                                  current === member.identifier ? null : member.identifier
                                )
                              }
                              className="flex h-[28px] w-[152px] items-center justify-between gap-1.5 rounded-md border border-[rgba(135,135,135,0.18)] bg-black/20 px-2.5 text-[10px] font-semibold uppercase tracking-[0.08em] text-white/75 transition-colors hover:border-[rgba(var(--color-primary-rgb),0.28)] hover:text-[var(--color-primary)]"
                            >
                              <span className="truncate text-left">{selectedRoleData.name}</span>
                              <span
                                className={`material-symbols-outlined text-[14px] transition-transform ${
                                  memberRolePicker === member.identifier ? 'rotate-180' : ''
                                }`}
                              >
                                expand_more
                              </span>
                            </button>
                          </div>

                          <button
                            onClick={() =>
                              setConfirmation({
                                title: t('permissions_remove_member', 'Remove Member'),
                                message: t('permissions_remove_member_confirm', 'Remove this member from the selected role?'),
                                onConfirm: () => {
                                  handleSetMemberRole(member.identifier, '');
                                  setMemberRolePicker(null);
                                  setConfirmation(null);
                                },
                              })
                            }
                            className="text-white/35 transition-colors hover:text-red-300"
                          >
                            <span className="material-symbols-outlined text-[18px]">close</span>
                          </button>
                        </div>
                      )}
                    </div>
                  ))
                )}
              </div>

              {isOwner && (
                <div className="relative mt-3" ref={memberPickerRef}>
                  {memberPickerOpen && (
                    <div className="absolute bottom-[calc(100%+8px)] left-0 right-0 z-20 overflow-hidden rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(40,40,40,0.96)_0%,rgba(28,28,28,0.88)_100%)] shadow-[0_10px_30px_rgba(0,0,0,0.35)]">
                      <div className="max-h-[170px] overflow-y-auto p-1">
                        {availableOnlinePlayers.length === 0 ? (
                          <div className="px-3 py-3 text-[12px] text-white/45">
                            {t('permissions_no_online_members', 'No online members available')}
                          </div>
                        ) : (
                          availableOnlinePlayers.map((player) => (
                            <button
                              key={player.identifier}
                              onClick={() => {
                                handleSetMemberRole(player.source, selectedRoleData.id);
                                setMemberPickerOpen(false);
                              }}
                              className="flex w-full items-center justify-between rounded-md px-3 py-2 text-left transition-colors hover:bg-[rgba(var(--color-primary-rgb),0.1)]"
                            >
                              <div className="min-w-0 pr-3">
                                <p className="truncate text-[12px] font-semibold text-white">{player.name}</p>
                                <p className="mt-0.5 text-[10px] text-white/35">
                                  {t('permissions_player_id', 'Player ID: {id}', { id: player.source })}
                                </p>
                              </div>
                              <span className="material-symbols-outlined text-[16px] text-[var(--color-primary)]">
                                person_add
                              </span>
                            </button>
                          ))
                        )}
                      </div>
                    </div>
                  )}

                  <button
                    type="button"
                    disabled={availableOnlinePlayers.length === 0}
                    onClick={() => setMemberPickerOpen((open) => !open)}
                    className={`flex h-[38px] w-full items-center justify-between rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(40,40,40,0.94)_0%,rgba(28,28,28,0.8)_100%)] px-3 text-[13px] text-white transition-colors ${
                      availableOnlinePlayers.length === 0
                        ? 'cursor-not-allowed opacity-45'
                        : 'hover:border-[rgba(var(--color-primary-rgb),0.28)]'
                    }`}
                  >
                    <span className="truncate text-left">
                      {availableOnlinePlayers.length === 0
                        ? t('permissions_no_online_members', 'No online members available')
                        : t('permissions_add_online_member', 'Add online member...')}
                    </span>
                    <span
                      className={`material-symbols-outlined text-[18px] text-white/70 transition-transform ${
                        memberPickerOpen ? 'rotate-180' : ''
                      }`}
                    >
                      expand_more
                    </span>
                  </button>
                </div>
              )}
            </div>
          </>
        )}
      </div>
    );
  };

  const panel = (
    <div className="relative flex flex-col h-[610px] w-[530px] overflow-hidden rounded-lg border border-neutral-500 bg-black/70 p-4 font-[Inter]">
      {renderHeader()}
      <div className="mt-4 flex flex-1 flex-col overflow-hidden">
        {renderNavigation()}
        <div className="flex flex-1 flex-col overflow-hidden">{renderMainContent()}</div>
      </div>

      {editingRole && (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/70">
          <div className="w-[340px] rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(20,20,20,0.95)_0%,rgba(15,15,15,0.9)_100%)] p-4">
            <p className="text-lg font-bold uppercase tracking-wide text-white">
              {editingRole.id ? t('permissions_rename_role', 'Rename Role') : t('permissions_create_role_title', 'Create Role')}
            </p>
            <input
              type="text"
              value={editingRole.name || ''}
              onChange={(event) => setEditingRole({ ...editingRole, name: event.target.value })}
              className="mt-4 h-[40px] w-full rounded-md border border-[rgba(135,135,135,0.18)] bg-[rgba(255,255,255,0.03)] px-3 text-sm text-white focus:outline-none focus:border-[rgba(var(--color-primary-rgb),0.35)]"
              placeholder={t('permissions_role_name', 'Role name')}
              autoFocus
            />
            <div className="mt-4 grid grid-cols-2 gap-3">
              <button
                disabled={isSubmitting}
                onClick={() => {
                  if (isSubmitting || !editingRole.name?.trim()) return;
                  setIsSubmitting(true);

                  if (!editingRole.id) {
                    fetchNui('benchPermissions:createRole', {
                      benchId: data?.benchId,
                      name: editingRole.name,
                      permissions: { use: true, move: false, pack: false, manage: false },
                    });
                  } else {
                    handleUpdateRole(editingRole);
                  }

                  setEditingRole(null);
                  setIsSubmitting(false);
                }}
                className="h-[40px] rounded-md bg-[var(--color-primary)] text-[13px] font-bold uppercase tracking-[0.08em] text-[#1b2d26] transition hover:brightness-105 disabled:opacity-60"
              >
                {t('permissions_save', 'Save')}
              </button>
              <button
                onClick={() => setEditingRole(null)}
                className="h-[40px] rounded-md border border-[rgba(135,135,135,0.18)] bg-[rgba(255,255,255,0.03)] text-[13px] font-bold uppercase tracking-[0.08em] text-white transition hover:bg-white/5"
              >
                {t('permissions_cancel', 'Cancel')}
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmation && (
        <div className="absolute inset-0 z-[60] flex items-center justify-center bg-black/70">
          <div className="w-[340px] rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(20,20,20,0.95)_0%,rgba(15,15,15,0.9)_100%)] p-4">
            <p className="text-lg font-bold uppercase tracking-wide text-white">{confirmation.title}</p>
            <p className="mt-2 text-sm leading-relaxed text-white/70">{confirmation.message}</p>
            <div className="mt-4 grid grid-cols-2 gap-3">
              <button
                onClick={confirmation.onConfirm}
                className="h-[40px] rounded-md bg-red-500/90 text-[13px] font-bold uppercase tracking-[0.08em] text-white transition hover:bg-red-500"
              >
                {Locale.ui_confirm || t('permissions_confirm', 'Confirm')}
              </button>
              <button
                onClick={() => setConfirmation(null)}
                className="h-[40px] rounded-md border border-[rgba(135,135,135,0.18)] bg-[rgba(255,255,255,0.03)] text-[13px] font-bold uppercase tracking-[0.08em] text-white transition hover:bg-white/5"
              >
                {t('permissions_cancel', 'Cancel')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  if (embedded) return panel;

  return <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80">{panel}</div>;
};

export default BenchPermissions;
