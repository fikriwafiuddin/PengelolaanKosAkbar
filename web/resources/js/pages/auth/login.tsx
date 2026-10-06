import { Form, Head } from '@inertiajs/react';
import InputError from '@/components/input-error';
import PasswordInput from '@/components/password-input';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Spinner } from '@/components/ui/spinner';
import { store } from '@/routes/login';

type Props = {
    status?: string;
};

export default function Login({ status }: Props) {
    return (
        <>
            <Head title="Masuk" />

            <Form
                action={store.url()}
                method="post"
                resetOnSuccess={['password']}
                className="flex flex-col gap-6"
            >
                {({ processing, errors }) => (
                    <div className="grid gap-6">
                        <div className="grid gap-2">
                            <Label htmlFor="email">Email</Label>
                            <Input
                                id="email"
                                type="email"
                                name="email"
                                required
                                autoFocus
                                tabIndex={1}
                                autoComplete="email"
                                placeholder="admin@kostakbar.id"
                            />
                            <InputError message={errors.email} />
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="password">Kata Sandi</Label>
                            <PasswordInput
                                id="password"
                                name="password"
                                required
                                tabIndex={2}
                                autoComplete="current-password"
                                placeholder="Kata sandi"
                            />
                            <InputError message={errors.password} />
                        </div>

                        <div className="flex items-center space-x-3">
                            <Checkbox id="remember" name="remember" tabIndex={3} />
                            <Label htmlFor="remember">Ingat Saya</Label>
                        </div>

                        <Button
                            type="submit"
                            className="mt-4 w-full"
                            tabIndex={4}
                            disabled={processing}
                            data-test="login-button"
                        >
                            {processing && <Spinner />}
                            Masuk Sekarang
                        </Button>
                    </div>
                )}
            </Form>

            {status && (
                <div className="mt-4 mb-4 text-center text-sm font-medium text-green-600">
                    {status}
                </div>
            )}

            <p className="mt-6 text-center text-xs text-muted-foreground">
                Dashboard web khusus admin Kost Akbar. Penghuni silakan masuk
                melalui aplikasi mobile.
            </p>
        </>
    );
}

Login.layout = {
    title: 'Masuk ke Kost Akbar',
    description: 'Silakan masuk menggunakan akun admin yang terdaftar.',
};
