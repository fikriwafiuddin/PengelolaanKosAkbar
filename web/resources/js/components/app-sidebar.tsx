import { Link, router } from '@inertiajs/react';
import { LogOut } from 'lucide-react';
import AppLogo from '@/components/app-logo';
import { NavMain } from '@/components/nav-main';
import { NavUser } from '@/components/nav-user';
import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    SidebarGroup,
    SidebarGroupLabel,
    SidebarHeader,
    SidebarMenu,
    SidebarMenuButton,
    SidebarMenuItem,
} from '@/components/ui/sidebar';
import { mainNavItems, upcomingNavItems } from '@/lib/admin-nav';
import { logout } from '@/routes';

export function AppSidebar() {
    return (
        <Sidebar collapsible="icon" variant="inset" className="print:hidden">
            <SidebarHeader>
                <SidebarMenu>
                    <SidebarMenuItem>
                        <SidebarMenuButton size="lg" asChild>
                            <Link href={mainNavItems[0].href} prefetch>
                                <AppLogo />
                            </Link>
                        </SidebarMenuButton>
                    </SidebarMenuItem>
                </SidebarMenu>
            </SidebarHeader>

            <SidebarContent>
                <NavMain items={mainNavItems} />

                {/* Menu sprint berikutnya — tampil sesuai desain, belum aktif */}
                <SidebarGroup className="px-2 py-0">
                    <SidebarGroupLabel>Segera Hadir</SidebarGroupLabel>
                    <SidebarMenu>
                        {upcomingNavItems.map((item) => (
                            <SidebarMenuItem key={item.title}>
                                <SidebarMenuButton
                                    disabled
                                    tooltip={{
                                        children: `${item.title} — hadir pada ${item.sprint}`,
                                    }}
                                >
                                    {item.icon && <item.icon />}
                                    <span>{item.title}</span>
                                    <span className="ml-auto text-[0.6rem] font-medium tracking-wide text-muted-foreground uppercase">
                                        {item.sprint}
                                    </span>
                                </SidebarMenuButton>
                            </SidebarMenuItem>
                        ))}
                    </SidebarMenu>
                </SidebarGroup>
            </SidebarContent>

            <SidebarFooter>
                <SidebarMenu>
                    <SidebarMenuItem>
                        <SidebarMenuButton
                            tooltip={{ children: 'Keluar' }}
                            onClick={() => router.post(logout())}
                        >
                            <LogOut />
                            <span>Keluar</span>
                        </SidebarMenuButton>
                    </SidebarMenuItem>
                    <NavUser />
                </SidebarMenu>
            </SidebarFooter>
        </Sidebar>
    );
}
